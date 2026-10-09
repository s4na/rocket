import Foundation
import XCTest

@testable import RocketCore

final class ApplicationSelectionTests: XCTestCase {
  func testSearchUsesNameAndBundleIdentifierIgnoringCase() {
    let alpha = application("Alpha", identifier: "org.example.first")
    let beta = application("Beta", identifier: "org.example.second")
    XCTAssertEqual(ApplicationSelection.filtered([beta, alpha], query: " ALPHA "), [alpha])
    XCTAssertEqual(ApplicationSelection.filtered([beta, alpha], query: "SECOND"), [beta])
    XCTAssertEqual(ApplicationSelection.filtered([beta, alpha], query: " \n"), [alpha, beta])
    XCTAssertEqual(ApplicationSelection.filtered([beta, alpha], query: "missing"), [])
  }

  func testEqualNamesHaveStableBundleIdentifierOrder() {
    let first = application("Same", identifier: "org.example.a")
    let second = application("Same", identifier: "org.example.b")
    XCTAssertEqual(ApplicationSelection.filtered([second, first], query: ""), [first, second])
  }

  func testQueryChangeKeepsSelectionOnlyWhileItRemainsVisible() {
    let alpha = application("Alpha")
    let beta = application("Beta")
    XCTAssertEqual(ApplicationSelection.reconciled(beta.id, in: [alpha, beta]), beta.id)
    XCTAssertEqual(ApplicationSelection.reconciled(beta.id, in: [alpha]), alpha.id)
    XCTAssertNil(ApplicationSelection.reconciled(beta.id, in: []))
    XCTAssertEqual(ApplicationSelection.reconciled(nil, in: [alpha, beta]), alpha.id)
  }

  func testArrowSelectionClampsToVisibleListAndHandlesEmptyList() {
    let alpha = application("Alpha")
    let beta = application("Beta")
    let applications = [alpha, beta]
    XCTAssertEqual(ApplicationSelection.moved(alpha.id, by: 1, in: applications), beta.id)
    XCTAssertEqual(ApplicationSelection.moved(beta.id, by: -1, in: applications), alpha.id)
    XCTAssertEqual(ApplicationSelection.moved(alpha.id, by: -1, in: applications), alpha.id)
    XCTAssertEqual(ApplicationSelection.moved(beta.id, by: 1, in: applications), beta.id)
    XCTAssertEqual(ApplicationSelection.moved(nil, by: 1, in: applications), alpha.id)
    XCTAssertNil(ApplicationSelection.moved(beta.id, by: 1, in: []))
  }

  private func application(_ name: String, identifier: String? = nil) -> RegisteredApplication {
    RegisteredApplication(
      name: name, bundleIdentifier: identifier ?? "org.example.\(name.lowercased())",
      path: "/Applications/\(name).app", bookmark: Data()
    )
  }
}
