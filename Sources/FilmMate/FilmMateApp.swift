import SwiftUI

@main
struct FilmMateApp: App {
    @StateObject private var settings = SettingsViewModel()

    init() {
        // Apply saved language immediately on launch
        let saved = UserDefaults.standard.string(forKey: "app_language") ?? "de-DE"
        LanguageManager.apply(saved)
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                // language change → new id → SwiftUI rebuilds entire view tree
                // → all String(localized:) calls re-evaluate with the new bundle
                .id(settings.language)
                .environmentObject(settings)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1000, height: 640)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
