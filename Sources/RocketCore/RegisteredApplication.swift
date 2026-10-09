import Foundation

/// A user-selected application. The UUID survives moves and bookmark refreshes.
public struct RegisteredApplication: Codable, Equatable, Identifiable, Sendable {
  public let id: UUID
  public var name: String
  public let bundleIdentifier: String
  public var path: String
  public var bookmark: Data

  public init(
    id: UUID = UUID(), name: String, bundleIdentifier: String, path: String, bookmark: Data
  ) {
    self.id = id
    self.name = name
    self.bundleIdentifier = bundleIdentifier
    self.path = path
    self.bookmark = bookmark
  }
}
