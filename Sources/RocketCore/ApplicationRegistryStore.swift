import Foundation

/// Versioned local storage. Invalid/unsupported files are never silently overwritten.
public struct ApplicationRegistryStore {
  public let fileURL: URL

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public func load() throws -> [RegisteredApplication] {
    let data: Data
    do {
      data = try Data(contentsOf: fileURL)
    } catch let error as NSError where error.domain == NSCocoaErrorDomain
      && error.code == NSFileReadNoSuchFileError {
      return []
    }
    let document = try JSONDecoder().decode(Document.self, from: data)
    guard document.version == 1 else { throw StorageError.unsupportedVersion(document.version) }
    try validate(document.applications)
    return document.applications
  }

  public func save(_ applications: [RegisteredApplication]) throws {
    // Recheck before every write so an unreadable file cannot be replaced by an empty registry.
    _ = try load()
    try validate(applications)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(Document(version: 1, applications: applications))
    try FileManager.default.createDirectory(
      at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
    )
    try data.write(to: fileURL, options: .atomic)
  }

  private func validate(_ applications: [RegisteredApplication]) throws {
    var identifiers = Set<UUID>()
    var bundleIdentifiers = Set<String>()
    for application in applications {
      guard !application.name.isEmpty,
         !application.bundleIdentifier.isEmpty,
         application.path.hasPrefix("/"),
         identifiers.insert(application.id).inserted,
         bundleIdentifiers.insert(application.bundleIdentifier).inserted
      else { throw StorageError.invalidApplications }
    }
  }

  private struct Document: Codable {
    let version: Int
    let applications: [RegisteredApplication]
  }

  public enum StorageError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidApplications

    public var errorDescription: String? {
      switch self {
      case .unsupportedVersion(let version):
        return "The application list uses an unsupported format (version \(version))."
      case .invalidApplications:
        return "The saved application list contains invalid or duplicate entries."
      }
    }
  }
}
