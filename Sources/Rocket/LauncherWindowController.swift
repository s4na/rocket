import AppKit
import RocketCore
import SwiftUI

final class LauncherPanel: NSPanel {
  override var canBecomeKey: Bool { true }
}

@MainActor
final class LauncherWindowController: NSObject, NSWindowDelegate {
  private let panel: LauncherPanel
  private var presentation = LauncherPresentation()
  private var previousApplication: NSRunningApplication?

  override init() {
    panel = LauncherPanel(
      contentRect: NSRect(x: 0, y: 0, width: 560, height: 320),
      styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false
    )
    super.init()
    panel.title = "Rocket"
    panel.titleVisibility = .hidden
    panel.titlebarAppearsTransparent = true
    panel.isReleasedWhenClosed = false
    panel.level = .floating
    panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
    panel.delegate = self
    panel.contentView = NSHostingView(rootView: LauncherView { [weak self] in self?.dismiss() })
  }

  func show() {
    if !presentation.isPresented {
      previousApplication = NSWorkspace.shared.frontmostApplication
      let mouse = NSEvent.mouseLocation
      let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
      if let visible = screen?.visibleFrame {
        panel.setFrameOrigin(
          NSPoint(x: visible.midX - panel.frame.width / 2, y: visible.midY - panel.frame.height / 2)
        )
      }
    }
    presentation.show()
    NSApp.activate(ignoringOtherApps: true)
    panel.makeKeyAndOrderFront(nil)
  }

  func dismiss(restoreFocus: Bool = true) {
    guard presentation.isPresented else { return }
    presentation.dismiss()
    panel.orderOut(nil)
    if restoreFocus, let previousApplication, !previousApplication.isTerminated,
      previousApplication.processIdentifier != ProcessInfo.processInfo.processIdentifier
    {
      previousApplication.activate(options: [])
    }
    previousApplication = nil
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    dismiss()
    return false
  }

  func windowDidResignKey(_ notification: Notification) {
    // Do not steal focus back when the user deliberately selects another app.
    dismiss(restoreFocus: false)
  }
}
