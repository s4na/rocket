import AppKit

@MainActor
enum ApplicationMenu {
  static func install() {
    let menu = NSMenu()
    let applicationItem = NSMenuItem()
    let applicationMenu = NSMenu()
    applicationMenu.addItem(
      NSMenuItem(
        title: "Quit Rocket", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"
      )
    )
    applicationItem.submenu = applicationMenu
    menu.addItem(applicationItem)

    let editItem = NSMenuItem()
    let editMenu = NSMenu(title: "Edit")
    for (title, action, key) in [
      ("Cut", #selector(NSText.cut(_:)), "x"),
      ("Copy", #selector(NSText.copy(_:)), "c"),
      ("Paste", #selector(NSText.paste(_:)), "v"),
      ("Select All", #selector(NSText.selectAll(_:)), "a"),
    ] {
      editMenu.addItem(NSMenuItem(title: title, action: action, keyEquivalent: key))
    }
    editItem.submenu = editMenu
    menu.addItem(editItem)
    NSApp.mainMenu = menu
  }
}
