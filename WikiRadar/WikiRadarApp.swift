import SwiftUI

@main
struct WikiRadarApp: App {
  @Environment(\.scenePhase) private var scenePhase
  @State private var model = AppModel()

  var body: some Scene {
    WindowGroup {
      ArticleListView()
        .environment(model)
    }
    .onChange(of: scenePhase) { _, phase in
      switch phase {
      case .active: model.setActive(true)
      case .background: model.setActive(false)
      default: break
      }
    }
  }
}
