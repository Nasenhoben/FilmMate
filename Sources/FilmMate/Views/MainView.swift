import SwiftUI
import AppKit

struct MainView: View {
    @StateObject private var vm = MovieViewModel()
    @EnvironmentObject private var settings: SettingsViewModel
    @State private var showSettings = false

    var body: some View {
        HStack(spacing: 0) {
            FilterSidebarView(vm: vm, onSettings: { showSettings = true })

            Divider()

            ZStack {
                Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
                contentArea
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 870, minHeight: 520)
        .sheet(isPresented: $showSettings) {
            SettingsSheet(settings: settings, vm: vm, isPresented: $showSettings)
        }
        .preferredColorScheme(settings.colorScheme)
        .background(WindowConfigurator())
    }

    @ViewBuilder
    private var contentArea: some View {
        if !vm.hasDatabase {
            EmptyDatabaseView(onSetup: { showSettings = true })
                .transition(.opacity)
        } else if !vm.suggestedMovies.isEmpty {
            SuggestedMovieView(vm: vm)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
        } else {
            WelcomeView(vm: vm)
                .transition(.opacity)
        }
    }
}

// MARK: - Empty database

struct EmptyDatabaseView: View {
    let onSetup: () -> Void
    @State private var hovered = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 96, height: 96)
                Image(systemName: "film.stack")
                    .font(.system(size: 42))
                    .foregroundStyle(Color.accentColor)
            }
            VStack(spacing: 8) {
                Text(String(localized: "empty.title"))
                    .font(.title3).fontWeight(.bold)
                Text(String(localized: "empty.subtitle"))
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).frame(maxWidth: 300)
            }
            Button(action: onSetup) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                    Text(String(localized: "action.setup"))
                }
                .font(.callout).fontWeight(.semibold)
                .padding(.horizontal, 20).padding(.vertical, 9)
                .background(Color.accentColor).foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                .scaleEffect(hovered ? 1.03 : 1.0)
            }
            .buttonStyle(.plain)
            .onHover { hovered = $0 }
            .animation(.spring(duration: 0.2), value: hovered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Welcome

struct WelcomeView: View {
    @ObservedObject var vm: MovieViewModel

    var body: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 140, height: 140)
                Image(systemName: "popcorn.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 10) {
                Text(String(localized: "welcome.title"))
                    .font(.title).fontWeight(.bold)

                if vm.filteredCount > 0 {
                    // Prominente Filmanzahl
                    HStack(spacing: 6) {
                        Text("\(vm.filteredCount)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.accentColor)
                        Text(String(localized: "welcome.count_suffix"))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20).padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.08))
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
                } else if vm.hasDatabase {
                    Text(String(localized: "welcome.no_results"))
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                } else {
                    Text(String(localized: "welcome.subtitle"))
                        .font(.subheadline).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center).frame(maxWidth: 320)
                }
            }

            // Hinweis auf Tastaturkürzel
            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                    .font(.system(size: 11))
                Text("⌘R")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                Text("·")
                Text(String(localized: "action.suggest_now"))
                    .font(.system(size: 11))
            }
            .foregroundStyle(.tertiary)
            .opacity(vm.filteredCount > 0 ? 1 : 0)
        }
        .animation(.spring(duration: 0.3), value: vm.filteredCount)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 5-card suggestion view

struct SuggestedMovieView: View {
    @ObservedObject var vm: MovieViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                HStack {
                    Text(String(localized: "suggestion.title"))
                        .font(.headline)
                    Spacer()
                    Button { vm.suggestRandom() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "shuffle")
                            Text(String(localized: "action.another"))
                        }
                        .font(.callout)
                        .padding(.horizontal, 13).padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(vm.suggestedMovies.enumerated()), id: \.element.id) { index, movie in
                        MovieGridCard(movie: movie)
                            .animation(
                                Animation.spring(duration: 0.38, bounce: 0.08)
                                    .delay(Double(index) * 0.055),
                                value: vm.suggestedMovies.map(\.id)
                            )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
        }
        .animation(Animation.spring(duration: 0.35), value: vm.suggestedMovies.map(\.id))
    }
}

// MARK: - Window configurator (transparente Titelleiste + Ampel-Buttons)

private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

// MARK: - Settings sheet

struct SettingsSheet: View {
    @ObservedObject var settings: SettingsViewModel
    @ObservedObject var vm: MovieViewModel
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Color.accentColor)
                    Text(String(localized: "action.settings"))
                        .font(.headline)
                }
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            SettingsView(settings: settings, vm: vm)
        }
        .frame(width: 500)
        .onDisappear { vm.updateComplete = false }
    }
}
