/// Re-fetch the list when we've moved far enough from where it was fetched,
/// but not more often than once a minute — same rule as the phone companion.
enum AutoRefreshGate {
  static let distanceMeters = 300.0
  static let minIntervalSeconds = 60.0

  static func shouldRefresh(movedMeters: Double,
                            secondsSinceFetch: Double) -> Bool {
    secondsSinceFetch >= minIntervalSeconds && movedMeters > distanceMeters
  }
}
