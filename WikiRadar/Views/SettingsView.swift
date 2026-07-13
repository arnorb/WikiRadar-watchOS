import SwiftUI

struct SettingsView: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    @Bindable var settings = model.settings
    NavigationStack {
      List {
        Section {
          Picker("Language", selection: $settings.language) {
            ForEach(SettingsStore.languages, id: \.code) { language in
              Text(language.name).tag(language.code)
            }
          }
          TextField("Custom code", text: $settings.customLanguage)
            .textInputAutocapitalization(.never)
          Picker("Search radius", selection: $settings.radiusMeters) {
            ForEach(SettingsStore.radiusOptionsMeters, id: \.self) { radius in
              Text("\(radius / 1000) km").tag(radius)
            }
          }
        } header: {
          Text("Wikipedia")
        } footer: {
          Text("Any Wikipedia language code as custom code, e.g. " +
               "“haw” for Hawaiian, overrides the language above.")
        }
        Section("Display") {
          Toggle("Imperial units", isOn: $settings.imperialUnits)
          Picker("Article text size", selection: $settings.textSize) {
            Text("Follow watch setting").tag(0)
            Text("Small").tag(1)
            Text("Medium").tag(2)
            Text("Large").tag(3)
            Text("Extra large").tag(4)
          }
        }
      }
      .navigationTitle("Settings")
    }
    // Search settings changes refetch the list, as the phone companion did
    .onChange(of: settings.effectiveLanguage) { model.refresh() }
    .onChange(of: settings.radiusMeters) { model.refresh() }
  }
}
