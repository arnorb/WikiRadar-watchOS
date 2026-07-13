import CoreLocation
import XCTest

final class GeoMathTests: XCTestCase {
  private let origin =
      CLLocationCoordinate2D(latitude: 64.1466, longitude: -21.9426)

  private func bearing(toLat lat: Double, lon: Double) -> Double {
    GeoMath.bearing(from: origin,
                    to: CLLocationCoordinate2D(latitude: lat, longitude: lon))
  }

  func testCardinalDirections() {
    XCTAssertEqual(bearing(toLat: 64.2, lon: -21.9426), 0, accuracy: 0.01)
    XCTAssertEqual(bearing(toLat: 64.1466, lon: -21.8), 90, accuracy: 0.01)
    XCTAssertEqual(bearing(toLat: 64.1, lon: -21.9426), 180, accuracy: 0.01)
    XCTAssertEqual(bearing(toLat: 64.1466, lon: -22.0), 270, accuracy: 0.01)
  }

  func testDiagonalAtEquator() {
    let bearing = GeoMath.bearing(
        from: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        to: CLLocationCoordinate2D(latitude: 0.01, longitude: 0.01))
    XCTAssertEqual(bearing, 45, accuracy: 0.01)
  }

  func testSamePointIsZero() {
    XCTAssertEqual(GeoMath.bearing(from: origin, to: origin), 0)
  }
}
