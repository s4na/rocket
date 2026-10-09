import AppKit
import ApplicationServices
import RocketCore

/// Permission checks never prompt. Only the explicit setup action may prompt.
enum AccessibilityStatus: Equatable {
  case granted
  case notGranted
}

enum WindowTilingError: LocalizedError {
  case accessibilityPermissionRequired
  case noExternalApplication
  case noFocusedWindow
  case unsupportedWindow
  case fullScreenWindow
  case noScreen
  case operationInProgress
  case accessibilityFailure(code: Int32)
  case placementRejected(restored: Bool)

  var errorDescription: String? {
    switch self {
    case .accessibilityPermissionRequired:
      return "Window shortcuts need Accessibility access. "
        + "Choose Enable Window Shortcuts in Rocket's menu to set it up."
    case .noExternalApplication:
      return "Focus a window in another app, then press the window shortcut."
    case .noFocusedWindow:
      return "The frontmost app has no focused window to move."
    case .unsupportedWindow:
      return "This window does not support moving and resizing. Try a regular app window."
    case .fullScreenWindow:
      return "Exit macOS full screen before using a window shortcut."
    case .noScreen:
      return "No available display was found. Try again after your display is connected."
    case .operationInProgress:
      return "A window move is still in progress. Try the shortcut again in a moment."
    case .accessibilityFailure(let code):
      return "The app could not complete the window operation "
        + "(Accessibility error \(code)). Try again."
    case .placementRejected(let restored):
      let outcome =
        restored ? "The original frame was restored." : "The window may have moved or resized."
      return "The app did not accept this placement, possibly because of its minimum window size. "
        + outcome
    }
  }
}

@MainActor
final class WindowTilingController {
  private let workQueue = DispatchQueue(label: "rocket.window-tiling", qos: .userInitiated)
  private var operationInProgress = false

  var accessibilityStatus: AccessibilityStatus {
    AXIsProcessTrusted() ? .granted : .notGranted
  }

  /// Call only from the user's explicit Enable Window Shortcuts action.
  /// The prompt is asynchronous: `notGranted` does not mean the user declined.
  @discardableResult
  func requestAccessibilityPermission() -> AccessibilityStatus {
    let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
    let trusted = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    return trusted ? .granted : .notGranted
  }

  /// Call directly from the hotkey callback, without activating Rocket first.
  /// Capture the application AND focused window now; never reuse launcher focus.
  /// Completion is always called on the main thread. No permission prompt occurs.
  func tileFrontmostWindow(
    _ placement: WindowPlacement,
    completion: @escaping (Result<Void, WindowTilingError>) -> Void
  ) {
    guard accessibilityStatus == .granted else {
      completion(.failure(.accessibilityPermissionRequired))
      return
    }
    guard !operationInProgress else {
      completion(.failure(.operationInProgress))
      return
    }
    guard let app = NSWorkspace.shared.frontmostApplication,
      app.processIdentifier != ProcessInfo.processInfo.processIdentifier,
      !app.isTerminated
    else {
      completion(.failure(.noExternalApplication))
      return
    }
    let screens = NSScreen.screens.map {
      WindowScreen(frame: $0.frame, visibleFrame: $0.visibleFrame)
    }
    guard let primary = screens.first else {
      completion(.failure(.noScreen))
      return
    }
    let window: AXUIElement
    do {
      window = try WindowAccessibility.focusedWindow(processIdentifier: app.processIdentifier)
    } catch let error as WindowTilingError {
      completion(.failure(error))
      return
    } catch {
      completion(.failure(.unsupportedWindow))
      return
    }
    operationInProgress = true
    workQueue.async {
      let result = WindowAccessibility.tile(
        window, placement: placement, screens: screens, primaryScreenFrame: primary.frame
      )
      DispatchQueue.main.async {
        self.operationInProgress = false
        completion(result)
      }
    }
  }
}

private enum WindowAccessibility {
  /// Keep the synchronous focus capture bounded if the target app is hung.
  static func focusedWindow(processIdentifier: pid_t) throws -> AXUIElement {
    let app = AXUIElementCreateApplication(processIdentifier)
    AXUIElementSetMessagingTimeout(app, 0.25)
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value)
    if result == .noValue || result == .attributeUnsupported {
      throw WindowTilingError.noFocusedWindow
    }
    try check(result)
    guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else {
      throw WindowTilingError.noFocusedWindow
    }
    // AX references require a CF downcast; the type ID was checked above.
    let window = value as! AXUIElement
    AXUIElementSetMessagingTimeout(window, 0.25)
    return window
  }

  static func tile(
    _ window: AXUIElement,
    placement: WindowPlacement,
    screens: [WindowScreen],
    primaryScreenFrame: CGRect
  ) -> Result<Void, WindowTilingError> {
    do {
      try validate(window)
      let original = try frame(of: window)
      let appKitFrame = WindowGeometry.appKitFrame(
        fromAccessibility: original, primaryScreenFrame: primaryScreenFrame
      )
      guard let index = WindowGeometry.screenIndex(for: appKitFrame, screens: screens) else {
        throw WindowTilingError.noScreen
      }
      let target = WindowGeometry.accessibilityFrame(
        fromAppKit: WindowGeometry.targetFrame(for: placement, in: screens[index].visibleFrame),
        primaryScreenFrame: primaryScreenFrame
      )
      guard target.width > 0, target.height > 0 else { throw WindowTilingError.noScreen }
      if WindowGeometry.approximatelyEqual(original, target) { return .success(()) }
      do {
        try setFrame(target, on: window)
        guard waitForFrame(target, on: window) else {
          throw WindowTilingError.placementRejected(restored: false)
        }
      } catch {
        // AX may partially apply a frame or silently enforce a minimum
        // size. Restore best-effort and report whether it actually stuck.
        try? setFrame(original, on: window)
        let restored = waitForFrame(original, on: window)
        throw WindowTilingError.placementRejected(restored: restored)
      }
      return .success(())
    } catch let error as WindowTilingError {
      return .failure(error)
    } catch {
      return .failure(.unsupportedWindow)
    }
  }

  private static func validate(_ window: AXUIElement) throws {
    if try optionalBoolean("AXFullScreen", on: window) == true {
      throw WindowTilingError.fullScreenWindow
    }
    if try optionalBoolean(kAXMinimizedAttribute, on: window) == true {
      throw WindowTilingError.unsupportedWindow
    }
    for attribute in [kAXPositionAttribute, kAXSizeAttribute] {
      var settable: DarwinBoolean = false
      try check(AXUIElementIsAttributeSettable(window, attribute as CFString, &settable))
      guard settable.boolValue else { throw WindowTilingError.unsupportedWindow }
    }
  }

  private static func optionalBoolean(_ attribute: String, on window: AXUIElement) throws -> Bool? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(window, attribute as CFString, &value)
    if result == .attributeUnsupported || result == .noValue { return nil }
    try check(result)
    return (value as? NSNumber)?.boolValue
  }

  private static func frame(of window: AXUIElement) throws -> CGRect {
    var position = CGPoint.zero
    var size = CGSize.zero
    let positionValue = try axValue(kAXPositionAttribute, type: .cgPoint, on: window)
    let sizeValue = try axValue(kAXSizeAttribute, type: .cgSize, on: window)
    guard AXValueGetValue(positionValue, .cgPoint, &position),
      AXValueGetValue(sizeValue, .cgSize, &size),
      position.x.isFinite, position.y.isFinite,
      size.width.isFinite, size.height.isFinite,
      size.width > 0, size.height > 0
    else {
      throw WindowTilingError.unsupportedWindow
    }
    return CGRect(origin: position, size: size)
  }

  private static func axValue(
    _ attribute: String, type: AXValueType, on window: AXUIElement
  ) throws -> AXValue {
    var value: CFTypeRef?
    try check(AXUIElementCopyAttributeValue(window, attribute as CFString, &value))
    guard let value, CFGetTypeID(value) == AXValueGetTypeID() else {
      throw WindowTilingError.unsupportedWindow
    }
    let axValue = value as! AXValue
    guard AXValueGetType(axValue) == type else { throw WindowTilingError.unsupportedWindow }
    return axValue
  }

  private static func setFrame(_ frame: CGRect, on window: AXUIElement) throws {
    var size = frame.size
    var position = frame.origin
    guard let sizeValue = AXValueCreate(.cgSize, &size),
      let positionValue = AXValueCreate(.cgPoint, &position)
    else {
      throw WindowTilingError.unsupportedWindow
    }
    // Shrink first so screen-edge clamping does not prevent positioning;
    // reapply size after moving for apps that constrain size by location.
    try check(AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue))
    try check(AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue))
    try check(AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue))
  }

  private static func waitForFrame(_ expected: CGRect, on window: AXUIElement) -> Bool {
    // A few apps apply AX writes on their next run-loop turn. Bound settling
    // time on the worker queue, never sleep on the app's main thread.
    for attempt in 0..<4 {
      if let actual = try? frame(of: window), WindowGeometry.approximatelyEqual(actual, expected) {
        return true
      }
      if attempt < 3 { Thread.sleep(forTimeInterval: 0.05) }
    }
    return false
  }

  private static func check(_ result: AXError) throws {
    guard result == .success else {
      if result == .apiDisabled { throw WindowTilingError.accessibilityPermissionRequired }
      if result == .attributeUnsupported || result == .notImplemented {
        throw WindowTilingError.unsupportedWindow
      }
      throw WindowTilingError.accessibilityFailure(code: result.rawValue)
    }
  }
}
