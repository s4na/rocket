/// Keeps repeated shortcut presses predictable without creating extra windows.
public struct LauncherPresentation {
  public private(set) var isPresented = false

  public init() {}

  public mutating func show() {
    isPresented = true
  }

  public mutating func dismiss() {
    isPresented = false
  }
}
