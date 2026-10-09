import AppKit
import SwiftUI

/// Handles arrows while the search editor has focus, without installing event taps or monitors.
struct LauncherSearchField: NSViewRepresentable {
  @Binding var text: String
  var onMove: (Int) -> Void
  var onSubmit: () -> Void
  var onCancel: () -> Void

  func makeCoordinator() -> Coordinator { Coordinator(self) }

  func makeNSView(context: Context) -> NSSearchField {
    let field = FocusingSearchField()
    field.placeholderString = "Search applications"
    field.setAccessibilityLabel("Search applications")
    field.sendsSearchStringImmediately = true
    field.delegate = context.coordinator
    return field
  }

  func updateNSView(_ field: NSSearchField, context: Context) {
    context.coordinator.owner = self
    if field.stringValue != text { field.stringValue = text }
  }

  final class Coordinator: NSObject, NSSearchFieldDelegate {
    var owner: LauncherSearchField

    init(_ owner: LauncherSearchField) { self.owner = owner }

    func controlTextDidChange(_ notification: Notification) {
      guard let field = notification.object as? NSSearchField else { return }
      owner.text = field.stringValue
    }

    func control(
      _ control: NSControl, textView: NSTextView, doCommandBy selector: Selector
    ) -> Bool {
      // Let the input method own navigation/Return while composing text (for example, Japanese).
      guard !textView.hasMarkedText() else { return false }
      switch selector {
      case #selector(NSResponder.moveUp(_:)):
        owner.onMove(-1)
      case #selector(NSResponder.moveDown(_:)):
        owner.onMove(1)
      case #selector(NSResponder.insertNewline(_:)):
        owner.onSubmit()
      case #selector(NSResponder.cancelOperation(_:)):
        owner.onCancel()
      default:
        return false
      }
      return true
    }
  }
}

private final class FocusingSearchField: NSSearchField {
  private var activationObserver: NSObjectProtocol?

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if let activationObserver { NotificationCenter.default.removeObserver(activationObserver) }
    activationObserver = nil
    guard let window else { return }
    activationObserver = NotificationCenter.default.addObserver(
      forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main
    ) { [weak self] _ in
      self?.focusSearch()
    }
    DispatchQueue.main.async { [weak self] in self?.focusSearch() }
  }

  private func focusSearch() {
    guard let window, window.isKeyWindow else { return }
    window.makeFirstResponder(self)
  }

  deinit {
    if let activationObserver { NotificationCenter.default.removeObserver(activationObserver) }
  }
}
