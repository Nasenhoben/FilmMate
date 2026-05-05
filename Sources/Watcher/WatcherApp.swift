import SwiftUI

@main
struct WatcherApp: App {
    @StateObject private var settings = SettingsViewModel()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(settings)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1100, height: 680)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
