import XCTest

@testable import RocketCore

final class LauncherPresentationTests: XCTestCase {
  func testRepeatedShowAndDismissAreIdempotent() {
    var presentation = LauncherPresentation()
    XCTAssertFalse(presentation.isPresented)
    presentation.show()
    presentation.show()
    XCTAssertTrue(presentation.isPresented)
    presentation.dismiss()
    presentation.dismiss()
    XCTAssertFalse(presentation.isPresented)
    presentation.show()
    XCTAssertTrue(presentation.isPresented)
  }
}
