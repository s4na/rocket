import CoreGraphics
import Foundation
import XCTest

@testable import RocketCore

final class WindowGeometryTests: XCTestCase {
  func testAllPlacementsUseVisibleFrameWithDockAndMenuOffsets() {
    let visible = CGRect(x: 40, y: 80, width: 1_200, height: 800)
    let cases: [(WindowPlacement, CGRect)] = [
      (.leftHalf, CGRect(x: 40, y: 80, width: 600, height: 800)),
      (.rightHalf, CGRect(x: 640, y: 80, width: 600, height: 800)),
      (.topHalf, CGRect(x: 40, y: 480, width: 1_200, height: 400)),
      (.bottomHalf, CGRect(x: 40, y: 80, width: 1_200, height: 400)),
      (.topLeft, CGRect(x: 40, y: 480, width: 600, height: 400)),
      (.topRight, CGRect(x: 640, y: 480, width: 600, height: 400)),
      (.bottomLeft, CGRect(x: 40, y: 80, width: 600, height: 400)),
      (.bottomRight, CGRect(x: 640, y: 80, width: 600, height: 400)),
      (.maximize, visible),
    ]
    XCTAssertEqual(cases.count, WindowPlacement.allCases.count)
    for (placement, expected) in cases {
      XCTAssertEqual(
        WindowGeometry.targetFrame(for: placement, in: visible), expected, placement.rawValue
      )
    }
  }

  func testOddSizedVisibleFrameHasNoGapOrOverlap() {
    let visible = CGRect(x: -1_601, y: -99, width: 1_601, height: 901)
    let left = WindowGeometry.targetFrame(for: .leftHalf, in: visible)
    let right = WindowGeometry.targetFrame(for: .rightHalf, in: visible)
    let top = WindowGeometry.targetFrame(for: .topHalf, in: visible)
    let bottom = WindowGeometry.targetFrame(for: .bottomHalf, in: visible)
    XCTAssertEqual(left.maxX, right.minX)
    XCTAssertEqual(bottom.maxY, top.minY)
    XCTAssertEqual(left.union(right), visible)
    XCTAssertEqual(top.union(bottom), visible)
  }

  func testCoordinateConversionUsesPrimaryDisplayForEveryDisplayPosition() {
    let primary = CGRect(x: 0, y: 0, width: 1_440, height: 900)
    let cases: [(CGRect, CGRect)] = [
      (
        CGRect(x: 100, y: 100, width: 600, height: 700),
        CGRect(x: 100, y: 100, width: 600, height: 700)
      ),
      (
        CGRect(x: -1_200, y: 100, width: 500, height: 700),
        CGRect(x: -1_200, y: 100, width: 500, height: 700)
      ),
      (
        CGRect(x: 1_440, y: 200, width: 800, height: 600),
        CGRect(x: 1_440, y: 100, width: 800, height: 600)
      ),
      (
        CGRect(x: 0, y: 1_000, width: 800, height: 600),
        CGRect(x: 0, y: -700, width: 800, height: 600)
      ),
      (
        CGRect(x: 0, y: -800, width: 800, height: 600),
        CGRect(x: 0, y: 1_100, width: 800, height: 600)
      ),
    ]
    for (appKit, accessibility) in cases {
      XCTAssertEqual(
        WindowGeometry.accessibilityFrame(
          fromAppKit: appKit, primaryScreenFrame: primary
        ), accessibility
      )
      XCTAssertEqual(
        WindowGeometry.appKitFrame(
          fromAccessibility: accessibility, primaryScreenFrame: primary
        ), appKit
      )
    }
  }

  func testTopRightQuarterOnDisplayAbovePrimary() {
    let primary = CGRect(x: 0, y: 0, width: 1_440, height: 900)
    let upperVisible = CGRect(x: -200, y: 900, width: 1_600, height: 975)
    let target = WindowGeometry.targetFrame(for: .topRight, in: upperVisible)
    XCTAssertEqual(target, CGRect(x: 600, y: 1_387.5, width: 800, height: 487.5))
    XCTAssertEqual(
      WindowGeometry.accessibilityFrame(fromAppKit: target, primaryScreenFrame: primary),
      CGRect(x: 600, y: -975, width: 800, height: 487.5)
    )
  }

  func testSelectsLargestOverlapInsteadOfFirstOrMainScreen() {
    let screens = [screen(x: 0, y: 0), screen(x: -1_000, y: 0)]
    let window = CGRect(x: -600, y: 100, width: 800, height: 500)
    XCTAssertEqual(WindowGeometry.screenIndex(for: window, screens: screens), 1)
  }

  func testSelectsDisplayAboveAndBelowPrimary() {
    let screens = [screen(x: 0, y: 0), screen(x: 0, y: 800), screen(x: 0, y: -800)]
    XCTAssertEqual(
      WindowGeometry.screenIndex(
        for: CGRect(x: 100, y: 900, width: 600, height: 500), screens: screens
      ), 1
    )
    XCTAssertEqual(
      WindowGeometry.screenIndex(
        for: CGRect(x: 100, y: -700, width: 600, height: 500), screens: screens
      ), 2
    )
  }

  func testCenterBreaksEqualAreaTie() {
    let screens = [screen(x: 0, y: 0), screen(x: 1_000, y: 0)]
    let window = CGRect(x: 800, y: 100, width: 400, height: 400)
    XCTAssertEqual(WindowGeometry.screenIndex(for: window, screens: screens), 1)
  }

  func testOffScreenWindowUsesNearestDisplay() {
    let screens = [screen(x: 0, y: 0), screen(x: 1_000, y: 0)]
    let window = CGRect(x: 2_300, y: 50, width: 300, height: 300)
    XCTAssertEqual(WindowGeometry.screenIndex(for: window, screens: screens), 1)
  }

  func testNoScreensHasNoDestination() {
    XCTAssertNil(
      WindowGeometry.screenIndex(for: CGRect(x: 0, y: 0, width: 300, height: 300), screens: [])
    )
  }

  func testReadbackToleranceAllowsPixelRoundingButRejectsMinimumSizeClamp() {
    let expected = CGRect(x: -1_000, y: 24, width: 500.5, height: 400.5)
    XCTAssertTrue(
      WindowGeometry.approximatelyEqual(expected, CGRect(x: -999, y: 24, width: 501, height: 401))
    )
    XCTAssertFalse(
      WindowGeometry.approximatelyEqual(expected, CGRect(x: -1_000, y: 24, width: 700, height: 401))
    )
    XCTAssertFalse(
      WindowGeometry.approximatelyEqual(expected, CGRect(x: 0, y: 24, width: 501, height: 401))
    )
  }

  private func screen(x: CGFloat, y: CGFloat) -> WindowScreen {
    let frame = CGRect(x: x, y: y, width: 1_000, height: 800)
    return WindowScreen(frame: frame, visibleFrame: frame.insetBy(dx: 0, dy: 24))
  }
}
