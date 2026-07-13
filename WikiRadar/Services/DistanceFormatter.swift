enum DistanceFormatter {
  /// Same integer math and thresholds as the Pebble app: meters under 1 km,
  /// then one-decimal kilometers; feet under 1000 ft, then one-decimal miles.
  static func format(meters: Int, imperial: Bool) -> String {
    if imperial {
      let feet = meters * 328 / 100
      if feet < 1000 {
        return "\(feet) ft"
      }
      let tenthMiles = meters * 10 / 1609
      return "\(tenthMiles / 10).\(tenthMiles % 10) mi"
    }
    if meters < 1000 {
      return "\(meters) m"
    }
    let tenthKms = meters / 100
    return "\(tenthKms / 10).\(tenthKms % 10) km"
  }
}
