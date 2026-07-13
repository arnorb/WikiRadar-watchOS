import SwiftUI

struct ArticleDetailView: View {
  @Environment(AppModel.self) private var model
  let article: Article

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 8) {
        Text(article.title)
          .font(.title3.bold())
        // Direct destination: value-based links in pushed views can't
        // resolve a navigationDestination declared on the covered root
        NavigationLink(destination: CompassView(article: article)) {
          HStack(spacing: 6) {
            Image(systemName: "location.north.line.fill")
              .foregroundStyle(.cyan)
            VStack(alignment: .leading, spacing: 0) {
              Text(model.formattedDistance(to: article))
                .font(.headline)
              Text(coordinateText)
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            Spacer()
          }
        }
        .accessibilityIdentifier("compass-link")
        summaryText
          .accessibilityIdentifier("summary-text")
      }
      .padding(.horizontal, 2)
    }
    .onAppear { model.openArticle(article) }
  }

  /// 4 decimals ≈ 11 m precision, as in the Pebble article view.
  private var coordinateText: String {
    String(format: "%.4f, %.4f", article.lat, article.lon)
  }

  @ViewBuilder private var summaryText: some View {
    Group {
      if let text = model.summaries[article.pageid] {
        Text(text)
      } else if let message = model.summaryErrors[article.pageid] {
        Text(message).foregroundStyle(.secondary)
      } else {
        Text("Loading…").foregroundStyle(.secondary)
      }
    }
    .font(.body)
    .textSizeOverride(model.settings.textSize)
  }
}

extension View {
  /// 0 follows the watch-wide text size; 1–4 pin the article body to
  /// S/M/L/XL, mirroring the Pebble text-size setting.
  @ViewBuilder func textSizeOverride(_ preference: Int) -> some View {
    switch preference {
    case 1: dynamicTypeSize(.xSmall)
    case 2: dynamicTypeSize(.large)
    case 3: dynamicTypeSize(.xxLarge)
    case 4: dynamicTypeSize(.accessibility2)
    default: self
    }
  }
}
