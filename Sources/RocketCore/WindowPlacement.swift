import CoreGraphics

public enum WindowPlacement: String, CaseIterable, Sendable {
  case leftHalf
  case rightHalf
  case topHalf
  case bottomHalf
  case topLeft
  case topRight
  case bottomLeft
  case bottomRight
  case maximize

  public var title: String {
    switch self {
    case .leftHalf: return "Left Half"
    case .rightHalf: return "Right Half"
    case .topHalf: return "Top Half"
    case .bottomHalf: return "Bottom Half"
    case .topLeft: return "Top Left Quarter"
    case .topRight: return "Top Right Quarter"
    case .bottomLeft: return "Bottom Left Quarter"
    case .bottomRight: return "Bottom Right Quarter"
    case .maximize: return "Maximize"
    }
  }
}

/// Frames use AppKit's global, bottom-left-origin coordinate system, in points.
public struct WindowScreen: Equatable, Sendable {
  public let frame: CGRect
  public let visibleFrame: CGRect

  public init(frame: CGRect, visibleFrame: CGRect) {
    self.frame = frame
    self.visibleFrame = visibleFrame
  }
}

public enum WindowGeometry {
  /// Splits the usable area; never includes the Dock or menu bar.
  /// The two sides share the same dividing line even for odd-sized displays.
  public static func targetFrame(
    for placement: WindowPlacement, in visibleFrame: CGRect
  ) -> CGRect {
    let halfWidth = visibleFrame.width / 2
    let halfHeight = visibleFrame.height / 2
    switch placement {
    case .leftHalf:
      return CGRect(
        x: visibleFrame.minX, y: visibleFrame.minY, width: halfWidth, height: visibleFrame.height
      )
    case .rightHalf:
      return CGRect(
        x: visibleFrame.midX, y: visibleFrame.minY, width: halfWidth, height: visibleFrame.height
      )
    case .topHalf:
      return CGRect(
        x: visibleFrame.minX, y: visibleFrame.midY, width: visibleFrame.width, height: halfHeight
      )
    case .bottomHalf:
      return CGRect(
        x: visibleFrame.minX, y: visibleFrame.minY, width: visibleFrame.width, height: halfHeight
      )
    case .topLeft:
      return CGRect(
        x: visibleFrame.minX, y: visibleFrame.midY, width: halfWidth, height: halfHeight
      )
    case .topRight:
      return CGRect(
        x: visibleFrame.midX, y: visibleFrame.midY, width: halfWidth, height: halfHeight
      )
    case .bottomLeft:
      return CGRect(
        x: visibleFrame.minX, y: visibleFrame.minY, width: halfWidth, height: halfHeight
      )
    case .bottomRight:
      return CGRect(
        x: visibleFrame.midX, y: visibleFrame.minY, width: halfWidth, height: halfHeight
      )
    case .maximize:
      return visibleFrame
    }
  }

  /// AX uses a top-left origin relative to the PRIMARY display, including on
  /// secondary displays. Never flip around the target display's own height.
  public static func accessibilityFrame(
    fromAppKit frame: CGRect, primaryScreenFrame: CGRect
  ) -> CGRect {
    CGRect(
      x: frame.minX,
      y: primaryScreenFrame.maxY - frame.maxY,
      width: frame.width,
      height: frame.height
    )
  }

  public static func appKitFrame(
    fromAccessibility frame: CGRect, primaryScreenFrame: CGRect
  ) -> CGRect {
    CGRect(
      x: frame.minX,
      y: primaryScreenFrame.maxY - frame.maxY,
      width: frame.width,
      height: frame.height
    )
  }

  /// Selects the largest overlap, with center containment breaking ties. A
  /// disconnected display may leave a window off-screen: choose the nearest.
  public static func screenIndex(for window: CGRect, screens: [WindowScreen]) -> Int? {
    guard !screens.isEmpty else { return nil }
    let center = CGPoint(x: window.midX, y: window.midY)
    var bestIndex = 0
    var bestArea: CGFloat = -1
    var bestContainsCenter = false
    var bestDistance = CGFloat.greatestFiniteMagnitude
    for (index, screen) in screens.enumerated() {
      let intersection = window.intersection(screen.frame)
      let area = intersection.isNull ? 0 : intersection.width * intersection.height
      let containsCenter = screen.frame.contains(center)
      let dx = max(max(screen.frame.minX - center.x, 0), center.x - screen.frame.maxX)
      let dy = max(max(screen.frame.minY - center.y, 0), center.y - screen.frame.maxY)
      let distance = dx * dx + dy * dy
      if area > bestArea
        || (area == bestArea && containsCenter && !bestContainsCenter)
        || (area == bestArea && containsCenter == bestContainsCenter && distance < bestDistance)
      {
        bestIndex = index
        bestArea = area
        bestContainsCenter = containsCenter
        bestDistance = distance
      }
    }
    return bestIndex
  }

  public static func approximatelyEqual(
    _ lhs: CGRect, _ rhs: CGRect, tolerance: CGFloat = 2
  ) -> Bool {
    abs(lhs.minX - rhs.minX) <= tolerance
      && abs(lhs.minY - rhs.minY) <= tolerance
      && abs(lhs.width - rhs.width) <= tolerance
      && abs(lhs.height - rhs.height) <= tolerance
  }
}
