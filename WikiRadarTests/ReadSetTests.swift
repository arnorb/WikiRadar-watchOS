import XCTest

final class ReadSetTests: XCTestCase {
  func testRollingEvictionAtCapacity() {
    var set = ReadSet()
    for pageid in 1...31 {
      set.mark(pageid)
    }
    XCTAssertEqual(set.pageids.count, 30)
    XCTAssertFalse(set.contains(1), "oldest entry should be evicted")
    XCTAssertTrue(set.contains(2))
    XCTAssertTrue(set.contains(31))
  }

  func testMarkIsIdempotent() {
    var set = ReadSet()
    set.mark(7)
    set.mark(7)
    XCTAssertEqual(set.pageids, [7])
  }

  func testInitTruncatesOversizedPersistedList() {
    let set = ReadSet(pageids: Array(1...40))
    XCTAssertEqual(set.pageids.count, 30)
    XCTAssertTrue(set.contains(40))
    XCTAssertFalse(set.contains(10))
  }
}
