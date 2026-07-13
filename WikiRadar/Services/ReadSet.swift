/// Rolling set of the 30 most recently read articles — a port of the
/// Pebble app's persisted title-hash ring, keyed by pageid instead.
struct ReadSet {
  static let capacity = 30

  private(set) var pageids: [Int]

  init(pageids: [Int] = []) {
    self.pageids = Array(pageids.suffix(Self.capacity))
  }

  func contains(_ pageid: Int) -> Bool {
    pageids.contains(pageid)
  }

  mutating func mark(_ pageid: Int) {
    guard !contains(pageid) else { return }
    pageids.append(pageid)
    if pageids.count > Self.capacity {
      pageids.removeFirst(pageids.count - Self.capacity)
    }
  }
}
