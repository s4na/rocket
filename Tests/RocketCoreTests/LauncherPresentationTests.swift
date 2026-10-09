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

  func testOldLaunchCannotDismissReopenedPresentation() {
    var presentation = LauncherPresentation()
    presentation.show()
    let launchSession = presentation.sessionID
    presentation.show()
    XCTAssertTrue(presentation.isCurrentSession(launchSession))
    presentation.dismiss()
    XCTAssertFalse(presentation.isCurrentSession(launchSession))
    presentation.show()
    XCTAssertFalse(presentation.isCurrentSession(launchSession))
    XCTAssertTrue(presentation.isCurrentSession(presentation.sessionID))
  }
}
