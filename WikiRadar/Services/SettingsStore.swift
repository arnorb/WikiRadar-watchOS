import Foundation
import Observation

@Observable
final class SettingsStore {
  static let languages: [(code: String, name: String)] = [
    ("en", "English"), ("is", "Íslenska"), ("da", "Dansk"), ("no", "Norsk"),
    ("sv", "Svenska"), ("fi", "Suomi"), ("de", "Deutsch"),
    ("nl", "Nederlands"), ("fr", "Français"), ("es", "Español"),
    ("it", "Italiano"), ("pt", "Português"), ("pl", "Polski"),
    ("ru", "Русский"),
  ]
  static let radiusOptionsMeters = [1000, 2000, 5000, 10000]

  private let defaults: UserDefaults

  var language: String {
    didSet { defaults.set(language, forKey: "language") }
  }
  /// Any Wikipedia language code; overrides the picker when set.
  var customLanguage: String {
    didSet { defaults.set(customLanguage, forKey: "customLanguage") }
  }
  var radiusMeters: Int {
    didSet { defaults.set(radiusMeters, forKey: "radiusMeters") }
  }
  var imperialUnits: Bool {
    didSet { defaults.set(imperialUnits, forKey: "imperialUnits") }
  }
  /// 0 = follow the watch-wide text size; 1..4 = S/M/L/XL override.
  var textSize: Int {
    didSet { defaults.set(textSize, forKey: "textSize") }
  }

  var effectiveLanguage: String {
    let custom = customLanguage
      .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return custom.isEmpty ? language : custom
  }

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    language = defaults.string(forKey: "language") ?? "en"
    customLanguage = defaults.string(forKey: "customLanguage") ?? ""
    radiusMeters = defaults.object(forKey: "radiusMeters") as? Int ?? 10000
    imperialUnits = defaults.object(forKey: "imperialUnits") as? Bool
      ?? (Locale.current.measurementSystem == .us)
    textSize = defaults.integer(forKey: "textSize")
  }
}
