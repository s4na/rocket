import Carbon
import RocketCore

struct WindowShortcut {
  let placement: WindowPlacement
  let keyCode: UInt32
  let keyLabel: String

  static let modifiers = UInt32(controlKey | optionKey | cmdKey)
  static let all: [WindowShortcut] = [
    WindowShortcut(placement: .leftHalf, keyCode: UInt32(kVK_LeftArrow), keyLabel: "←"),
    WindowShortcut(placement: .rightHalf, keyCode: UInt32(kVK_RightArrow), keyLabel: "→"),
    WindowShortcut(placement: .topHalf, keyCode: UInt32(kVK_UpArrow), keyLabel: "↑"),
    WindowShortcut(placement: .bottomHalf, keyCode: UInt32(kVK_DownArrow), keyLabel: "↓"),
    WindowShortcut(placement: .topLeft, keyCode: UInt32(kVK_ANSI_1), keyLabel: "1"),
    WindowShortcut(placement: .topRight, keyCode: UInt32(kVK_ANSI_2), keyLabel: "2"),
    WindowShortcut(placement: .bottomLeft, keyCode: UInt32(kVK_ANSI_3), keyLabel: "3"),
    WindowShortcut(placement: .bottomRight, keyCode: UInt32(kVK_ANSI_4), keyLabel: "4"),
    WindowShortcut(placement: .maximize, keyCode: UInt32(kVK_Return), keyLabel: "Return"),
  ]

  var label: String { "\(placement.title) (⌃⌥⌘\(keyLabel))" }
}
