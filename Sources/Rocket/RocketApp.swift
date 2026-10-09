import AppKit
import Carbon

@main
struct RocketApp {
  @MainActor
  static func main() {
    let application = NSApplication.shared
    let delegate = AppDelegate()
    application.delegate = delegate
    application.setActivationPolicy(.accessory)
    withExtendedLifetime(delegate) { application.run() }
  }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusItem: NSStatusItem?
  private var shortcuts: GlobalShortcuts?
  private var launcher: LauncherWindowController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    launcher = LauncherWindowController()
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.image = NSImage(systemSymbolName: "paperplane", accessibilityDescription: "Rocket")
    let menu = NSMenu()
    let open = NSMenuItem(
      title: "Open Rocket (⌃⌥Space)", action: #selector(showLauncher), keyEquivalent: ""
    )
    open.target = self
    menu.addItem(open)
    menu.addItem(.separator())
    menu.addItem(
      NSMenuItem(
        title: "Quit Rocket", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"
      )
    )
    item.menu = menu
    statusItem = item
    do {
      let shortcuts = try GlobalShortcuts()
      try shortcuts.register(
        keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey | optionKey)
      ) { [weak self] in
        self?.showLauncher()
      }
      self.shortcuts = shortcuts
    } catch {
      let alert = NSAlert()
      alert.messageText = "Rocket shortcut unavailable"
      alert.informativeText = error.localizedDescription
      alert.runModal()
    }
  }

  @objc private func showLauncher() {
    launcher?.show()
  }
}
