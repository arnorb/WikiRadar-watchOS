import CoreLocation
import Observation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()

  private(set) var location: CLLocation?
  /// Degrees clockwise from north; nil while the compass has no valid
  /// reading (needs calibration or no heading hardware).
  private(set) var heading: Double?
  private(set) var authorization: CLAuthorizationStatus = .notDetermined

  /// Fires on every fix so the model can apply the auto-refresh rule.
  @ObservationIgnored var onLocationUpdate: ((CLLocation) -> Void)?

  var headingSupported: Bool { CLLocationManager.headingAvailable() }

  override init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
  }

  func start() {
    if manager.authorizationStatus == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }
    manager.startUpdatingLocation()
  }

  func stop() {
    manager.stopUpdatingLocation()
    stopHeading()
  }

  func startHeading() {
    guard headingSupported else { return }
    manager.startUpdatingHeading()
  }

  func stopHeading() {
    manager.stopUpdatingHeading()
    heading = nil
  }

  // MARK: - CLLocationManagerDelegate

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorization = manager.authorizationStatus
    if authorization == .authorizedWhenInUse ||
       authorization == .authorizedAlways {
      manager.startUpdatingLocation()
    }
  }

  func locationManager(_ manager: CLLocationManager,
                       didUpdateLocations locations: [CLLocation]) {
    guard let latest = locations.last else { return }
    location = latest
    onLocationUpdate?(latest)
  }

  func locationManager(_ manager: CLLocationManager,
                       didUpdateHeading newHeading: CLHeading) {
    if newHeading.headingAccuracy < 0 {
      heading = nil  // invalid reading: calibration needed
    } else if newHeading.trueHeading >= 0 {
      // Bearings are geodesic (true north), so prefer the true heading
      heading = newHeading.trueHeading
    } else {
      heading = newHeading.magneticHeading
    }
  }

  func locationManager(_ manager: CLLocationManager,
                       didFailWithError error: Error) {
    // Transient by design: keep the last fix; the UI shows waiting states
  }
}
