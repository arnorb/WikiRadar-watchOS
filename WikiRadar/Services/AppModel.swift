import CoreLocation
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
  enum Status: Equatable {
    case idle
    case locating
    case loading
    case error(String)
  }

  let settings: SettingsStore
  let locationService: LocationService

  private(set) var articles: [Article] = []
  private(set) var summaries: [Int: String] = [:]
  private(set) var summaryErrors: [Int: String] = [:]
  /// When the current list was successfully fetched (or cache fetch time).
  private(set) var fetchDate: Date?
  private(set) var status: Status = .idle

  private let client = WikipediaClient()
  private let defaults: UserDefaults
  private var readSet: ReadSet
  private var lastFetchLocation: CLLocation?
  private var lastAttemptDate: Date?
  private var refreshTask: Task<Void, Never>?
  private var startedOnce = false

  private struct CachedState: Codable {
    var articles: [Article]
    var summaries: [Int: String]
    var fetchDate: Date
  }

  init(settings: SettingsStore = SettingsStore(),
       locationService: LocationService = LocationService(),
       defaults: UserDefaults = .standard) {
    self.settings = settings
    self.locationService = locationService
    self.defaults = defaults
    readSet = ReadSet(
        pageids: defaults.array(forKey: "readPageids") as? [Int] ?? [])
    if let data = defaults.data(forKey: "cachedState"),
       let cached = try? JSONDecoder().decode(CachedState.self, from: data) {
      articles = cached.articles
      summaries = cached.summaries
      fetchDate = cached.fetchDate
    }
    locationService.onLocationUpdate = { [weak self] location in
      Task { @MainActor in self?.locationDidUpdate(location) }
    }
  }

  /// First appearance: start GPS and fetch, showing any cached list
  /// meanwhile — same launch behavior as the Pebble app.
  func start() {
    locationService.start()
    if !startedOnce {
      startedOnce = true
      refresh()
    }
  }

  /// GPS runs only while the app is active, like the Pebble app's
  /// subscribe-on-appear pattern.
  func setActive(_ active: Bool) {
    if active {
      locationService.start()
    } else {
      locationService.stop()
    }
  }

  func refresh() {
    refreshTask?.cancel()
    refreshTask = Task { await performRefresh() }
  }

  func isRead(_ article: Article) -> Bool {
    readSet.contains(article.pageid)
  }

  /// Live distance in meters, falling back to the fetch-time distance
  /// until a fix arrives.
  func distanceMeters(to article: Article) -> Int {
    if let location = locationService.location {
      return Int(location.distance(from: article.location).rounded())
    }
    return Int(article.distanceAtFetch.rounded())
  }

  func formattedDistance(to article: Article) -> String {
    DistanceFormatter.format(meters: distanceMeters(to: article),
                             imperial: settings.imperialUnits)
  }

  /// Marks the article read and refetches its summary. Always refetches,
  /// showing any cached text meanwhile — the Pebble app does the same.
  func openArticle(_ article: Article) {
    markRead(article)
    summaryErrors[article.pageid] = nil
    Task {
      do {
        let text = try await client.fetchSummary(
            pageid: article.pageid, lang: settings.effectiveLanguage)
        summaries[article.pageid] = text
        saveCache()
      } catch {
        if summaries[article.pageid] == nil {
          summaryErrors[article.pageid] = Self.message(for: error)
        }
      }
    }
  }

  // MARK: - Internals

  private func performRefresh() async {
    let location = await currentLocation()
    if Task.isCancelled { return }
    guard let location else {
      status = articles.isEmpty ? .error("No GPS fix") : .idle
      return
    }
    status = .loading
    // Recorded before the fetch completes so a slow request isn't
    // re-triggered by auto-refresh, as in the phone companion.
    lastFetchLocation = location
    lastAttemptDate = Date()
    do {
      let found = try await client.fetchNearby(
          lat: location.coordinate.latitude,
          lon: location.coordinate.longitude,
          radiusMeters: settings.radiusMeters,
          lang: settings.effectiveLanguage)
      articles = found
      fetchDate = Date()
      summaries = summaries.filter { pageid, _ in
        found.contains { $0.pageid == pageid }
      }
      status = .idle
      saveCache()
    } catch is CancellationError {
      // superseded by a newer refresh
    } catch {
      status = .error(Self.message(for: error))
    }
  }

  /// A fix no older than 30 s, waiting up to 15 s for one — the same
  /// freshness rules the phone companion used.
  private func currentLocation() async -> CLLocation? {
    if let usable = usableLocation() { return usable }
    status = .locating
    for _ in 0..<30 {
      try? await Task.sleep(for: .milliseconds(500))
      if Task.isCancelled { return nil }
      if let usable = usableLocation() { return usable }
    }
    return locationService.location  // a stale fix beats no fix
  }

  private func usableLocation() -> CLLocation? {
    guard let location = locationService.location,
          -location.timestamp.timeIntervalSinceNow < 30 else { return nil }
    return location
  }

  private func locationDidUpdate(_ location: CLLocation) {
    guard let lastFetchLocation, let lastAttemptDate else { return }
    let moved = location.distance(from: lastFetchLocation)
    let elapsed = Date().timeIntervalSince(lastAttemptDate)
    if AutoRefreshGate.shouldRefresh(movedMeters: moved,
                                     secondsSinceFetch: elapsed) {
      refresh()
    }
  }

  private func markRead(_ article: Article) {
    guard !readSet.contains(article.pageid) else { return }
    readSet.mark(article.pageid)
    defaults.set(readSet.pageids, forKey: "readPageids")
  }

  private func saveCache() {
    guard let fetchDate else { return }
    let state = CachedState(articles: articles, summaries: summaries,
                            fetchDate: fetchDate)
    if let data = try? JSONEncoder().encode(state) {
      defaults.set(data, forKey: "cachedState")
    }
  }

  private static func message(for error: Error) -> String {
    if let clientError = error as? WikipediaClient.ClientError {
      return clientError.errorDescription ?? "Wikipedia error"
    }
    return "Wikipedia error"
  }
}
