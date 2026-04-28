import SwiftUI

@main
struct FilmMateApp: App {
    @StateObject private var settings = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(settings)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1000, height: 640)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
