import SwiftUI

enum Route: Hashable {
  case detail(Article)
  case compass(Article)
}

struct ArticleListView: View {
  @Environment(AppModel.self) private var model
  @State private var path = NavigationPath()
  @State private var showSettings = false

  var body: some View {
    NavigationStack(path: $path) {
      content
        .navigationTitle("WikiRadar")
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Button {
              showSettings = true
            } label: {
              Image(systemName: "gear")
            }
          }
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              model.refresh()
            } label: {
              Image(systemName: "arrow.clockwise")
            }
          }
        }
        .sheet(isPresented: $showSettings) {
          SettingsView()
        }
        .navigationDestination(for: Route.self) { route in
          switch route {
          case .detail(let article):
            ArticleDetailView(article: article)
          case .compass(let article):
            CompassView(article: article)
          }
        }
    }
    .task { model.start() }
  }

  @ViewBuilder private var content: some View {
    if model.articles.isEmpty {
      emptyState
    } else {
      List {
        Section {
          ForEach(model.articles) { article in
            row(article)
          }
        } header: {
          Text(headerText)
        }
      }
    }
  }

  private var headerText: String {
    switch model.status {
    case .loading: return "Updating…"
    case .locating: return "Locating…"
    default: break
    }
    if let date = model.fetchDate {
      return "Updated \(date.formatted(date: .omitted, time: .shortened))"
    }
    return "Nearby"
  }

  private func row(_ article: Article) -> some View {
    NavigationLink(value: Route.detail(article)) {
      HStack(spacing: 4) {
        VStack(alignment: .leading, spacing: 2) {
          Text(article.title)
            .font(.headline)
            .lineLimit(2)
          Text(model.formattedDistance(to: article))
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
        if model.isRead(article) {
          Circle()
            .fill(.tint)
            .frame(width: 6, height: 6)
        }
      }
    }
    // The Pebble app's long-press shortcut straight to the compass
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
      Button {
        path.append(Route.compass(article))
      } label: {
        Label("Compass", systemImage: "location.north.line.fill")
      }
      .tint(.cyan)
    }
  }

  @ViewBuilder private var emptyState: some View {
    if model.locationService.authorization == .denied {
      errorView("Location access denied — allow WikiRadar in Settings")
    } else {
      switch model.status {
      case .locating:
        waitingView("Locating…")
      case .loading:
        waitingView("Loading…")
      case .error(let message):
        errorView(message)
      case .idle:
        errorView("No articles nearby")
      }
    }
  }

  private func waitingView(_ label: String) -> some View {
    VStack(spacing: 8) {
      ProgressView()
      Text(label).foregroundStyle(.secondary)
    }
  }

  private func errorView(_ message: String) -> some View {
    VStack(spacing: 8) {
      Text(message)
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)
      Button("Retry") { model.refresh() }
    }
    .padding(.horizontal, 4)
  }
}
