import Carbon
import RocketCore

enum WindowShortcutAction: Sendable {
  case arrow(WindowArrow)
  case placement(WindowPlacement)

  var title: String {
    switch self {
    case .arrow(let arrow):
      switch arrow {
      case .left: return "Move Left"
      case .right: return "Move Right"
      case .up: return "Move Up"
      case .down: return "Move Down"
      }
    case .placement(let placement): return placement.title
    }
  }
}

struct WindowShortcut {
  let action: WindowShortcutAction
  let keyCode: UInt32
  let keyLabel: String

  static let modifiers = UInt32(controlKey | optionKey | cmdKey)
  static let all: [WindowShortcut] = [
    WindowShortcut(action: .arrow(.left), keyCode: UInt32(kVK_LeftArrow), keyLabel: "←"),
    WindowShortcut(action: .arrow(.right), keyCode: UInt32(kVK_RightArrow), keyLabel: "→"),
    WindowShortcut(action: .arrow(.up), keyCode: UInt32(kVK_UpArrow), keyLabel: "↑"),
    WindowShortcut(action: .arrow(.down), keyCode: UInt32(kVK_DownArrow), keyLabel: "↓"),
    WindowShortcut(
      action: .placement(.topLeft), keyCode: UInt32(kVK_ANSI_1), keyLabel: "1"
    ),
    WindowShortcut(
      action: .placement(.topRight), keyCode: UInt32(kVK_ANSI_2), keyLabel: "2"
    ),
    WindowShortcut(
      action: .placement(.bottomLeft), keyCode: UInt32(kVK_ANSI_3), keyLabel: "3"
    ),
    WindowShortcut(
      action: .placement(.bottomRight), keyCode: UInt32(kVK_ANSI_4), keyLabel: "4"
    ),
    WindowShortcut(
      action: .placement(.maximize), keyCode: UInt32(kVK_Return), keyLabel: "Return"
    ),
  ]

  var label: String { "\(action.title) (⌃⌥⌘\(keyLabel))" }
}
