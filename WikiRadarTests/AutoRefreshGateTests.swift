import XCTest

final class AutoRefreshGateTests: XCTestCase {
  func testRefreshesAfterMovingFarEnough() {
    XCTAssertTrue(AutoRefreshGate.shouldRefresh(movedMeters: 301,
                                                secondsSinceFetch: 60))
    XCTAssertTrue(AutoRefreshGate.shouldRefresh(movedMeters: 5000,
                                                secondsSinceFetch: 3600))
  }

  func testTooSoonAfterLastFetch() {
    XCTAssertFalse(AutoRefreshGate.shouldRefresh(movedMeters: 5000,
                                                 secondsSinceFetch: 30))
  }

  func testNotFarEnough() {
    XCTAssertFalse(AutoRefreshGate.shouldRefresh(movedMeters: 200,
                                                 secondsSinceFetch: 3600))
    // Strictly greater than 300 m, matching the companion's `moved > 300`
    XCTAssertFalse(AutoRefreshGate.shouldRefresh(movedMeters: 300,
                                                 secondsSinceFetch: 3600))
  }
}
