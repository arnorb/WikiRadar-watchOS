import XCTest

final class WikipediaDecodingTests: XCTestCase {
  func testGeosearchDecoding() throws {
    let json = """
    {"batchcomplete":"","query":{"geosearch":[
      {"pageid":776970,"ns":0,"title":"Hallgrímskirkja",
       "lat":64.14166,"lon":-21.92666,"dist":712.5,"primary":""},
      {"pageid":146921,"ns":0,"title":"Perlan",
       "lat":64.12916,"lon":-21.91888,"dist":2301.2,"primary":""}
    ]}}
    """.data(using: .utf8)!
    let decoded = try JSONDecoder()
        .decode(WikipediaClient.GeosearchResponse.self, from: json)
    let items = try XCTUnwrap(decoded.query?.geosearch)
    XCTAssertEqual(items.count, 2)
    XCTAssertEqual(items[0].pageid, 776970)
    XCTAssertEqual(items[0].title, "Hallgrímskirkja")
    XCTAssertEqual(items[0].lat, 64.14166, accuracy: 1e-9)
    XCTAssertEqual(items[0].dist, 712.5, accuracy: 1e-9)
  }

  func testExtractDecoding() throws {
    let json = """
    {"batchcomplete":"","query":{"pages":{
      "776970":{"pageid":776970,"ns":0,"title":"Hallgrímskirkja",
                "extract":"Hallgrímskirkja is a Lutheran parish church."}
    }}}
    """.data(using: .utf8)!
    let decoded = try JSONDecoder()
        .decode(WikipediaClient.ExtractResponse.self, from: json)
    let page = try XCTUnwrap(decoded.query?.pages.values.first)
    XCTAssertEqual(page.extract,
                   "Hallgrímskirkja is a Lutheran parish church.")
  }

  func testMissingExtractDecodesAsNil() throws {
    let json = """
    {"query":{"pages":{"1":{"pageid":1,"ns":0,"title":"X"}}}}
    """.data(using: .utf8)!
    let decoded = try JSONDecoder()
        .decode(WikipediaClient.ExtractResponse.self, from: json)
    let page = try XCTUnwrap(decoded.query?.pages.values.first)
    XCTAssertNil(page.extract)
  }
}
