import XCTest

final class WikiRadarUITests: XCTestCase {
  func testListToDetailToCompass() {
    let app = XCUIApplication()
    app.launch()

    // List: geosearch results appear (needs network + simulated location)
    let firstCell = app.cells.firstMatch
    XCTAssertTrue(firstCell.waitForExistence(timeout: 30),
                  "article list should load")
    attachScreenshot(of: app, named: "list")
    firstCell.tap()

    // Detail: distance/compass link and a loaded summary
    let compassLink = app.buttons["compass-link"]
    XCTAssertTrue(compassLink.waitForExistence(timeout: 10))
    let summary = app.staticTexts["summary-text"]
    let loaded = NSPredicate(
        format: "exists == true AND label != 'Loading…'")
    let summaryLoaded = expectation(for: loaded, evaluatedWith: summary)
    wait(for: [summaryLoaded], timeout: 20)
    attachScreenshot(of: app, named: "detail")

    // Compass: full-screen dial view
    compassLink.tap()
    XCTAssertTrue(app.descendants(matching: .any)["compass-view"]
        .waitForExistence(timeout: 10))
    attachScreenshot(of: app, named: "compass")
  }

  private func attachScreenshot(of app: XCUIApplication, named name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
