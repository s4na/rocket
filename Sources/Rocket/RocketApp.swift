import AppKit
import Carbon
import RocketCore

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
  private let tiling = WindowTilingController()
  private let feedback = WindowActionFeedback()

  func applicationDidFinishLaunching(_ notification: Notification) {
    ApplicationMenu.install()
    launcher = LauncherWindowController()
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    item.button?.image = NSImage(systemSymbolName: "paperplane", accessibilityDescription: "Rocket")
    let menu = NSMenu()
    let open = NSMenuItem(
      title: "Open Rocket (⌃⌥Space)", action: #selector(showLauncher), keyEquivalent: ""
    )
    open.target = self
    menu.addItem(open)
    let windowMenu = NSMenu()
    let enable = NSMenuItem(
      title: "Enable Window Shortcuts", action: #selector(enableWindowShortcuts), keyEquivalent: ""
    )
    enable.target = self
    windowMenu.addItem(enable)
    windowMenu.addItem(.separator())
    for shortcut in WindowShortcut.all {
      let description = NSMenuItem(title: shortcut.label, action: nil, keyEquivalent: "")
      windowMenu.addItem(description)
    }
    let windowItem = NSMenuItem(title: "Window Shortcuts", action: nil, keyEquivalent: "")
    windowItem.submenu = windowMenu
    menu.addItem(windowItem)
    menu.addItem(.separator())
    menu.addItem(
      NSMenuItem(
        title: "Quit Rocket", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"
      )
    )
    item.menu = menu
    statusItem = item
    configureShortcuts()
  }

  private func configureShortcuts() {
    do {
      let shortcuts = try GlobalShortcuts()
      self.shortcuts = shortcuts
      var failures: [String] = []
      do {
        try shortcuts.register(
          keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey | optionKey)
        ) { [weak self] in
          self?.showLauncher()
        }
      } catch {
        failures.append("Open Rocket (⌃⌥Space): " + error.localizedDescription)
      }
      for shortcut in WindowShortcut.all {
        do {
          try shortcuts.register(
            keyCode: shortcut.keyCode, modifiers: WindowShortcut.modifiers
          ) { [weak self] in
            self?.tileWindow(shortcut.placement)
          }
        } catch {
          failures.append(shortcut.label + ": " + error.localizedDescription)
        }
      }
      if !failures.isEmpty { showShortcutError(failures.joined(separator: "\n\n")) }
    } catch {
      showShortcutError(error.localizedDescription)
    }
  }

  private func showShortcutError(_ message: String) {
    let alert = NSAlert()
    alert.messageText = "Some Rocket shortcuts are unavailable"
    alert.informativeText = message
    alert.runModal()
  }

  private func tileWindow(_ placement: WindowPlacement) {
    tiling.tileFrontmostWindow(placement) { [weak self] result in
      if case .failure(let error) = result {
        self?.statusItem?.button?.toolTip = error.localizedDescription
        self?.feedback.show(error.localizedDescription)
      }
    }
  }

  @objc private func enableWindowShortcuts() {
    let message: String
    if tiling.requestAccessibilityPermission() == .granted {
      message = "Window shortcuts are ready. Focus another app and use a window shortcut."
    } else {
      message =
        "Enable Rocket in System Settings → Privacy & Security → Accessibility. "
        + "Then focus another app and retry a window shortcut."
    }
    feedback.show(message)
  }

  @objc private func showLauncher() {
    launcher?.show()
  }
}
