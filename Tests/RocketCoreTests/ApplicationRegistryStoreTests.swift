import Foundation
import XCTest

@testable import RocketCore

final class ApplicationRegistryStoreTests: XCTestCase {
  private var directory: URL!
  private var store: ApplicationRegistryStore!

  override func setUpWithError() throws {
    directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    store = ApplicationRegistryStore(fileURL: directory.appendingPathComponent("nested/apps.json"))
  }

  override func tearDownWithError() throws {
    if FileManager.default.fileExists(atPath: directory.path) {
      try FileManager.default.removeItem(at: directory)
    }
  }

  func testMissingStoreLoadsEmptyWithoutCreatingFiles() throws {
    XCTAssertEqual(try store.load(), [])
    XCTAssertFalse(FileManager.default.fileExists(atPath: store.fileURL.path))
  }

  func testRoundTripAndRelocationPreserveIdentity() throws {
    var application = sampleApplication()
    try store.save([application])
    XCTAssertEqual(try store.load(), [application])
    let id = application.id
    application.path = "/Users/example/Applications/Example.app"
    application.bookmark = Data([4, 5, 6])
    try store.save([application])
    let loaded = try store.load()
    XCTAssertEqual(loaded, [application])
    XCTAssertEqual(loaded.first?.id, id)
  }

  func testCorruptFileIsNotOverwrittenBySave() throws {
    let corrupt = Data("{not JSON".utf8)
    try writeFixture(corrupt)
    XCTAssertThrowsError(try store.load())
    XCTAssertThrowsError(try store.save([]))
    XCTAssertEqual(try Data(contentsOf: store.fileURL), corrupt)
  }

  func testUnknownVersionIsPreserved() throws {
    let future = Data(#"{"version":2,"applications":[]}"#.utf8)
    try writeFixture(future)
    XCTAssertThrowsError(try store.load())
    XCTAssertThrowsError(try store.save([]))
    XCTAssertEqual(try Data(contentsOf: store.fileURL), future)
  }

  func testDuplicateBundleIsRejectedWithoutChangingSavedList() throws {
    let application = sampleApplication()
    try store.save([application])
    let duplicate = sampleApplication()
    XCTAssertNotEqual(application.id, duplicate.id)
    XCTAssertThrowsError(try store.save([application, duplicate]))
    XCTAssertEqual(try store.load(), [application])
  }

  func testDuplicateIDIsRejected() throws {
    let application = sampleApplication()
    let duplicate = RegisteredApplication(
      id: application.id, name: "Other", bundleIdentifier: "com.example.other",
      path: "/Applications/Other.app", bookmark: Data()
    )
    XCTAssertThrowsError(try store.save([application, duplicate]))
  }

  func testRelativePathIsRejected() {
    var application = sampleApplication()
    application.path = "Example.app"
    XCTAssertThrowsError(try store.save([application]))
  }

  private func writeFixture(_ data: Data) throws {
    try FileManager.default.createDirectory(
      at: store.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
    )
    try data.write(to: store.fileURL)
  }

  private func sampleApplication() -> RegisteredApplication {
    RegisteredApplication(
      name: "Example", bundleIdentifier: "com.example.app",
      path: "/Applications/Example.app", bookmark: Data([1, 2, 3])
    )
  }
}
