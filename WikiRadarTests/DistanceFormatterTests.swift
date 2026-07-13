import XCTest

final class DistanceFormatterTests: XCTestCase {
  func testMetric() {
    XCTAssertEqual(DistanceFormatter.format(meters: 0, imperial: false),
                   "0 m")
    XCTAssertEqual(DistanceFormatter.format(meters: 123, imperial: false),
                   "123 m")
    XCTAssertEqual(DistanceFormatter.format(meters: 999, imperial: false),
                   "999 m")
    XCTAssertEqual(DistanceFormatter.format(meters: 1000, imperial: false),
                   "1.0 km")
    XCTAssertEqual(DistanceFormatter.format(meters: 1250, imperial: false),
                   "1.2 km")
    XCTAssertEqual(DistanceFormatter.format(meters: 15640, imperial: false),
                   "15.6 km")
  }

  func testImperial() {
    XCTAssertEqual(DistanceFormatter.format(meters: 100, imperial: true),
                   "328 ft")
    XCTAssertEqual(DistanceFormatter.format(meters: 304, imperial: true),
                   "997 ft")
    // 1000 ft rolls over to tenth-mile display
    XCTAssertEqual(DistanceFormatter.format(meters: 305, imperial: true),
                   "0.1 mi")
    XCTAssertEqual(DistanceFormatter.format(meters: 1609, imperial: true),
                   "1.0 mi")
    XCTAssertEqual(DistanceFormatter.format(meters: 2500, imperial: true),
                   "1.5 mi")
  }
}
