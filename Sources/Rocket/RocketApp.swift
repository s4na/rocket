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
    let about = NSMenuItem(
      title: "About Rocket", action: #selector(showAbout), keyEquivalent: ""
    )
    about.target = self
    menu.addItem(about)
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
            self?.tileWindow(shortcut.action)
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

  private func tileWindow(_ action: WindowShortcutAction) {
    tiling.tileFrontmostWindow(action) { [weak self] result in
      if case .failure(let error) = result {
        self?.statusItem?.button?.toolTip = error.localizedDescription
        if case .accessibilityPermissionRequired = error {
          self?.feedback.showAccessibilityPermissionRequired()
        } else {
          self?.feedback.show(error.localizedDescription)
        }
      }
    }
  }

  @objc private func enableWindowShortcuts() {
    let message: String
    if tiling.requestAccessibilityPermission() == .granted {
      message = "Window shortcuts are ready. Focus another app and use a window shortcut."
    } else {
      feedback.showAccessibilityPermissionRequired()
      return
    }
    feedback.show(message)
  }

  @objc private func showLauncher() {
    launcher?.show()
  }

  @objc private func showAbout() {
    let bundle = Bundle.main
    let version =
      bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
      ?? "Unknown"
    let build =
      bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String
      ?? "Unknown"
    let appURL = bundle.bundleURL.resolvingSymlinksInPath()
    let isHomebrewInstall =
      appURL.pathComponents.contains { $0 == "Caskroom" || $0 == "Cellar" }
      || isInstalledByRocketCask(appURL: appURL, version: version)
    let installationDetails =
      isHomebrewInstall
      ? "Installed via Homebrew"
      : "Build path: \(appURL.path)"

    let alert = NSAlert()
    alert.messageText = "About Rocket"
    alert.informativeText = "Version: \(version) (\(build))\n\(installationDetails)"
    alert.alertStyle = .informational
    alert.icon = NSApp.applicationIconImage
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }

  private func isInstalledByRocketCask(appURL: URL, version: String) -> Bool {
    return ["/opt/homebrew", "/usr/local"].contains { prefix in
      let metadataURL = URL(fileURLWithPath: prefix)
        .appendingPathComponent("Caskroom/s4na-rocket/.metadata")
      guard
        let receiptData = try? Data(
          contentsOf: metadataURL.appendingPathComponent("INSTALL_RECEIPT.json")),
        let receipt = try? JSONSerialization.jsonObject(with: receiptData) as? [String: Any],
        let source = receipt["source"] as? [String: Any],
        source["tap"] as? String == "s4na/try-s4na-tap",
        source["version"] as? String == version,
        let artifacts = receipt["uninstall_artifacts"] as? [[String: Any]],
        let configData = try? Data(contentsOf: metadataURL.appendingPathComponent("config.json")),
        let config = try? JSONSerialization.jsonObject(with: configData) as? [String: Any]
      else {
        return false
      }

      let explicitConfig = config["explicit"] as? [String: Any]
      let environmentConfig = config["env"] as? [String: Any]
      let defaultConfig = config["default"] as? [String: Any]
      guard
        let appDirectory = explicitConfig?["appdir"] as? String
          ?? environmentConfig?["appdir"] as? String
          ?? defaultConfig?["appdir"] as? String
      else {
        return false
      }

      let appTarget = artifacts.compactMap { artifact -> String? in
        guard
          let app = artifact["app"] as? [Any], app.count > 1,
          let details = app[1] as? [String: Any]
        else {
          return nil
        }
        return details["target"] as? String ?? app[0] as? String
      }.first
      guard let appTarget else { return false }

      let expectedAppURL = URL(fileURLWithPath: appDirectory)
        .appendingPathComponent(appTarget)
        .standardizedFileURL.resolvingSymlinksInPath()
      return expectedAppURL == appURL.standardizedFileURL
    }
  }
}
