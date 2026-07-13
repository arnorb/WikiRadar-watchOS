import CoreLocation

enum GeoMath {
  /// Bearing from `from` to `to`, degrees clockwise from true north in
  /// 0..<360. Equirectangular approximation like the Pebble app's — exact
  /// enough for the ≤10 km ranges geosearch returns.
  static func bearing(from: CLLocationCoordinate2D,
                      to: CLLocationCoordinate2D) -> Double {
    let dx = (to.longitude - from.longitude) * cos(from.latitude * .pi / 180)
    let dy = to.latitude - from.latitude
    if dx == 0 && dy == 0 { return 0 }
    let degrees = atan2(dx, dy) * 180 / .pi
    return degrees < 0 ? degrees + 360 : degrees
  }
}
