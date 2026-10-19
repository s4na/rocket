import AppKit

/// A short, nonactivating notice: a failed shortcut must not steal the target app's focus.
@MainActor
final class WindowActionFeedback {
  private var panel: NSPanel?
  private var dismissal: Timer?

  func show(_ message: String, showsAccessibilitySettingsLink: Bool = false) {
    dismissal?.invalidate()
    panel?.orderOut(nil)
    let height: CGFloat = showsAccessibilitySettingsLink ? 160 : 130
    let notice = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 420, height: height),
      styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false
    )
    notice.level = .floating
    notice.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    notice.isReleasedWhenClosed = false
    notice.hasShadow = true
    notice.hidesOnDeactivate = false
    notice.ignoresMouseEvents = !showsAccessibilitySettingsLink
    let label = NSTextField(wrappingLabelWithString: message)
    label.frame = NSRect(
      x: 20, y: showsAccessibilitySettingsLink ? 56 : 20,
      width: 380, height: showsAccessibilitySettingsLink ? 84 : 90
    )
    label.font = .systemFont(ofSize: 14)
    notice.contentView?.addSubview(label)
    if showsAccessibilitySettingsLink {
      let settingsLink = NSButton(
        title: "Open Accessibility Settings…", target: self,
        action: #selector(openAccessibilitySettings)
      )
      settingsLink.isBordered = false
      settingsLink.contentTintColor = .linkColor
      settingsLink.alignment = .left
      settingsLink.frame = NSRect(x: 18, y: 18, width: 280, height: 26)
      notice.contentView?.addSubview(settingsLink)
    }
    let pointer = NSEvent.mouseLocation
    let screen = NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) } ?? NSScreen.main
    if let visible = screen?.visibleFrame {
      notice.setFrameOrigin(NSPoint(x: visible.midX - 210, y: visible.maxY - height - 30))
    }
    notice.orderFrontRegardless()
    panel = notice
    let duration: TimeInterval = showsAccessibilitySettingsLink ? 12 : 6
    dismissal = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
      self?.panel?.orderOut(nil)
    }
  }

  func showAccessibilityPermissionRequired() {
    show(
      "Window shortcuts need Accessibility access. Enable Rocket in System Settings, then retry.",
      showsAccessibilitySettingsLink: true
    )
  }

  @objc private func openAccessibilitySettings() {
    guard
      let url = URL(
        string:
          "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
      )
    else { return }
    NSWorkspace.shared.open(url)
  }
}
