import AppKit

/// A short, nonactivating notice: a failed shortcut must not steal the target app's focus.
@MainActor
final class WindowActionFeedback {
  private var panel: NSPanel?
  private var dismissal: Timer?

  func show(_ message: String) {
    dismissal?.invalidate()
    panel?.orderOut(nil)
    let notice = NSPanel(
      contentRect: NSRect(x: 0, y: 0, width: 420, height: 130),
      styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false
    )
    notice.level = .floating
    notice.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    notice.isReleasedWhenClosed = false
    notice.hasShadow = true
    notice.hidesOnDeactivate = false
    notice.ignoresMouseEvents = true
    let label = NSTextField(wrappingLabelWithString: message)
    label.frame = NSRect(x: 20, y: 20, width: 380, height: 90)
    label.font = .systemFont(ofSize: 14)
    notice.contentView?.addSubview(label)
    let pointer = NSEvent.mouseLocation
    let screen = NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) } ?? NSScreen.main
    if let visible = screen?.visibleFrame {
      notice.setFrameOrigin(NSPoint(x: visible.midX - 210, y: visible.maxY - 160))
    }
    notice.orderFrontRegardless()
    panel = notice
    dismissal = Timer.scheduledTimer(withTimeInterval: 6, repeats: false) { [weak self] _ in
      self?.panel?.orderOut(nil)
    }
  }
}
