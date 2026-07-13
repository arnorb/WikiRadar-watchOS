import XCTest

final class SettingsStoreTests: XCTestCase {
  private func freshStore() -> SettingsStore {
    SettingsStore(
        defaults: UserDefaults(
            suiteName: "SettingsStoreTests-\(UUID().uuidString)")!)
  }

  func testDefaults() {
    let settings = freshStore()
    XCTAssertEqual(settings.language, "en")
    XCTAssertEqual(settings.radiusMeters, 10000)
    XCTAssertEqual(settings.textSize, 0)
  }

  func testCustomLanguageOverridesPicker() {
    let settings = freshStore()
    XCTAssertEqual(settings.effectiveLanguage, "en")
    settings.customLanguage = "  HAW "
    XCTAssertEqual(settings.effectiveLanguage, "haw",
                   "custom code is trimmed, lowercased, and wins")
    settings.customLanguage = ""
    settings.language = "is"
    XCTAssertEqual(settings.effectiveLanguage, "is")
  }
}
