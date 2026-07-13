import Foundation

struct WikipediaClient {
  static let maxArticles = 20
  // Wikipedia rejects requests without an identifiable user agent (403)
  static let userAgent = "wikiradar-watchos/1.0 (arnor@arnor.is)"

  var session: URLSession = .shared

  enum ClientError: LocalizedError {
    case wikipedia
    case noSummary

    var errorDescription: String? {
      switch self {
      case .wikipedia: return "Wikipedia error"
      case .noSummary: return "No summary"
      }
    }
  }

  struct GeosearchResponse: Decodable {
    struct Query: Decodable { let geosearch: [Item] }
    struct Item: Decodable {
      let pageid: Int
      let title: String
      let lat: Double
      let lon: Double
      let dist: Double
    }
    let query: Query?
  }

  struct ExtractResponse: Decodable {
    struct Query: Decodable { let pages: [String: Page] }
    struct Page: Decodable { let extract: String? }
    let query: Query?
  }

  func fetchNearby(lat: Double, lon: Double, radiusMeters: Int,
                   lang: String) async throws -> [Article] {
    let url = apiURL(lang: lang, query: [
      URLQueryItem(name: "action", value: "query"),
      URLQueryItem(name: "list", value: "geosearch"),
      URLQueryItem(name: "gscoord", value: "\(lat)|\(lon)"),
      URLQueryItem(name: "gsradius", value: String(radiusMeters)),
      URLQueryItem(name: "gslimit", value: String(Self.maxArticles)),
      URLQueryItem(name: "format", value: "json"),
    ])
    let data = try await get(url)
    guard let items = try? JSONDecoder()
        .decode(GeosearchResponse.self, from: data).query?.geosearch else {
      throw ClientError.wikipedia
    }
    return items.map {
      Article(pageid: $0.pageid, title: $0.title, lat: $0.lat, lon: $0.lon,
              distanceAtFetch: $0.dist)
    }
  }

  /// TextExtracts with exintro returns the full intro section; the REST
  /// page/summary endpoint only returns the first paragraph.
  func fetchSummary(pageid: Int, lang: String) async throws -> String {
    let url = apiURL(lang: lang, query: [
      URLQueryItem(name: "action", value: "query"),
      URLQueryItem(name: "prop", value: "extracts"),
      URLQueryItem(name: "exintro", value: ""),
      URLQueryItem(name: "explaintext", value: ""),
      URLQueryItem(name: "redirects", value: "1"),
      URLQueryItem(name: "pageids", value: String(pageid)),
      URLQueryItem(name: "format", value: "json"),
    ])
    let data = try await get(url)
    guard let page = try? JSONDecoder()
        .decode(ExtractResponse.self, from: data).query?.pages.values.first,
        let extract = page.extract, !extract.isEmpty else {
      throw ClientError.noSummary
    }
    return extract
  }

  private func apiURL(lang: String, query: [URLQueryItem]) -> URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "\(lang).wikipedia.org"
    components.path = "/w/api.php"
    components.queryItems = query
    return components.url!
  }

  private func get(_ url: URL) async throws -> Data {
    var request = URLRequest(url: url)
    request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse,
          (200..<300).contains(http.statusCode) else {
      throw ClientError.wikipedia
    }
    return data
  }
}
