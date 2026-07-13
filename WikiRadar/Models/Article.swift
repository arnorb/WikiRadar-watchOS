import CoreLocation

struct Article: Codable, Identifiable, Hashable {
  let pageid: Int
  let title: String
  let lat: Double
  let lon: Double
  /// Meters from the location the list was fetched at (geosearch `dist`).
  let distanceAtFetch: Double

  var id: Int { pageid }

  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: lat, longitude: lon)
  }

  var location: CLLocation {
    CLLocation(latitude: lat, longitude: lon)
  }
}
