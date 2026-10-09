import AppKit
import Combine
import RocketCore
import UniformTypeIdentifiers

@MainActor
final class ApplicationRegistry: ObservableObject {
  @Published private(set) var applications: [RegisteredApplication] = []
  @Published private(set) var missingIDs: Set<UUID> = []
  @Published private(set) var canEdit = false
  @Published private(set) var isLaunching = false
  @Published var errorMessage: String?

  private let store: ApplicationRegistryStore

  init(store: ApplicationRegistryStore? = nil) {
    self.store = store ?? ApplicationRegistryStore(fileURL: Self.defaultFileURL)
    refresh()
  }

  static var defaultFileURL: URL {
    FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent("Library/Application Support/Rocket/applications.json")
  }

  func refresh() {
    do {
      let original = try store.load()
      var loaded = original
      var missing = Set<UUID>()
      for index in loaded.indices {
        guard let resolution = resolve(loaded[index]) else {
          missing.insert(loaded[index].id)
          continue
        }
        if resolution.needsBookmarkRefresh {
          loaded[index].path = resolution.url.path
          loaded[index].bookmark = try resolution.url.bookmarkData(
            options: [], includingResourceValuesForKeys: nil, relativeTo: nil
          )
        }
      }
      // Keep a relocated path/bookmark usable across the next restart.
      if loaded != original { try store.save(loaded) }
      applications = loaded
      missingIDs = missing
      canEdit = true
      errorMessage = nil
    } catch {
      canEdit = false
      errorMessage =
        "Could not load the application list. The saved file was left unchanged. "
        + error.localizedDescription
    }
  }

  func addApplications() {
    guard canEdit, let window = NSApp.keyWindow else { return }
    let panel = NSOpenPanel()
    panel.title = "Add Applications"
    panel.prompt = "Add"
    panel.allowedContentTypes = [.applicationBundle]
    panel.allowsMultipleSelection = true
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.treatsFilePackagesAsDirectories = false
    panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
    panel.beginSheetModal(for: window) { [weak self] response in
      guard response == .OK else { return }
      self?.register(panel.urls)
    }
  }

  private func register(_ urls: [URL]) {
    do {
      var updated = applications
      for url in urls {
        let bundle = try applicationBundle(at: url)
        guard let identifier = bundle.bundleIdentifier else { continue }
        let existing = updated.firstIndex { $0.bundleIdentifier == identifier }
        let application = RegisteredApplication(
          id: existing.map { updated[$0].id } ?? UUID(),
          name: (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
              ?? url.deletingPathExtension().lastPathComponent,
          bundleIdentifier: identifier,
          path: url.path,
          bookmark: try url.bookmarkData(
            options: [], includingResourceValuesForKeys: nil, relativeTo: nil
          )
        )
        if let existing { updated[existing] = application } else { updated.append(application) }
      }
      try store.save(updated)
      applications = updated
      refresh()
    } catch {
      errorMessage = "Could not add the applications. " + error.localizedDescription
    }
  }

  func remove(_ id: UUID) {
    guard canEdit else { return }
    do {
      let updated = applications.filter { $0.id != id }
      try store.save(updated)
      applications = updated
      missingIDs.remove(id)
      errorMessage = nil
    } catch {
      errorMessage = "Could not save the application list. " + error.localizedDescription
    }
  }

  func launch(
    _ application: RegisteredApplication, completion: @escaping (NSRunningApplication) -> Void
  ) {
    guard !isLaunching else { return }
    guard let resolution = resolve(application) else {
      missingIDs.insert(application.id)
      errorMessage = "\(application.name) could not be found. Add it again to update its location."
      return
    }
    let configuration = NSWorkspace.OpenConfiguration()
    // The presentation owner decides whether this request still owns foreground focus.
    configuration.activates = false
    isLaunching = true
    NSWorkspace.shared.openApplication(at: resolution.url, configuration: configuration) {
      [weak self] runningApplication, error in
      DispatchQueue.main.async {
        guard let self else { return }
        self.isLaunching = false
        if let error {
          self.errorMessage = "Could not open \(application.name). " + error.localizedDescription
        } else if let runningApplication {
          self.errorMessage = nil
          completion(runningApplication)
        } else {
          self.errorMessage =
            "Could not open \(application.name). No running application was returned."
        }
      }
    }
  }

  private func resolve(_ application: RegisteredApplication) -> Resolution? {
    var stale = false
    if let url = try? URL(
      resolvingBookmarkData: application.bookmark, options: [.withoutUI, .withoutMounting],
      relativeTo: nil, bookmarkDataIsStale: &stale
    ), matches(url, application: application) {
      return Resolution(url: url, needsBookmarkRefresh: stale || url.path != application.path)
    }
    let previousURL = URL(fileURLWithPath: application.path, isDirectory: true)
    if matches(previousURL, application: application) {
      return Resolution(url: previousURL, needsBookmarkRefresh: true)
    }
    if let url = NSWorkspace.shared.urlForApplication(
      withBundleIdentifier: application.bundleIdentifier
    ), matches(url, application: application) {
      return Resolution(url: url, needsBookmarkRefresh: true)
    }
    return nil
  }

  private func matches(_ url: URL, application: RegisteredApplication) -> Bool {
    guard let bundle = try? applicationBundle(at: url) else { return false }
    return bundle.bundleIdentifier == application.bundleIdentifier
  }

  private func applicationBundle(at url: URL) throws -> Bundle {
    guard url.isFileURL, url.pathExtension.lowercased() == "app",
      let bundle = Bundle(url: url),
      let identifier = bundle.bundleIdentifier, !identifier.isEmpty,
      let executable = bundle.executableURL,
      FileManager.default.isExecutableFile(atPath: executable.path)
    else { throw RegistryError.invalidApplication(url.lastPathComponent) }
    return bundle
  }

  private struct Resolution {
    let url: URL
    let needsBookmarkRefresh: Bool
  }

  private enum RegistryError: LocalizedError {
    case invalidApplication(String)

    var errorDescription: String? {
      switch self {
      case .invalidApplication(let name): return "\(name) is not a launchable application bundle."
      }
    }
  }
}
