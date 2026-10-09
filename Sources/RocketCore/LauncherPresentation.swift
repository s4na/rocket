import Foundation

/// Keeps repeated shortcut presses predictable without creating extra windows.
public struct LauncherPresentation {
  public private(set) var isPresented = false
  public private(set) var sessionID = UUID()

  public init() {}

  public mutating func show() {
    if !isPresented { sessionID = UUID() }
    isPresented = true
  }

  public func isCurrentSession(_ id: UUID) -> Bool {
    isPresented && sessionID == id
  }

  public mutating func dismiss() {
    isPresented = false
  }
}
