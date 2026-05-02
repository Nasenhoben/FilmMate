import SwiftUI
import AppKit

// MARK: - App tabs

enum AppTab: CaseIterable {
    case discover, watchlist

    var label: String {
        switch self {
        case .discover:  return String(localized: "tab.discover")
        case .watchlist: return String(localized: "tab.watchlist")
        }
    }

    var icon: String {
        switch self {
        case .discover:  return "sparkles"
        case .watchlist: return "bookmark.fill"
        }
    }
}

// MARK: - Main view

struct MainView: View {
    @StateObject private var vm = MovieViewModel()
    @EnvironmentObject private var settings: SettingsViewModel
    @State private var showSettings = false
    @State private var showFilter = false
    @State private var activeTab: AppTab = .discover

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider()
            ZStack {
                Color(nsColor: .windowBackgroundColor).ignoresSafeArea()
                if activeTab == .discover {
                    contentArea.transition(.opacity)
                } else {
                    WatchlistOverviewView().transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.18), value: activeTab)
        }
        .ignoresSafeArea(edges: .top)
        .frame(minWidth: 800, minHeight: 560)
        .sheet(isPresented: $showSettings) {
            SettingsSheet(settings: settings, vm: vm, isPresented: $showSettings)
        }
        .preferredColorScheme(settings.colorScheme)
        .background(WindowConfigurator())
    }

    // MARK: - Top bar

    private var activeFilterCount: Int {
        (vm.mediaTypeFilter != .all ? 1 : 0) +
        (vm.selectedProviders.isEmpty ? 0 : 1) +
        (vm.minimumRating > 0 ? 1 : 0) +
        (vm.runtimeFilter != .all ? 1 : 0) +
        (vm.selectedGenres.isEmpty ? 0 : 1)
    }

    private var databaseOutdated: Bool {
        guard let lastUpdated = DatabaseService.shared.lastUpdated else { return false }
        return Date().timeIntervalSince(lastUpdated) > 14 * 24 * 3600
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            // Tab switcher
            HStack(spacing: 2) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { activeTab = tab }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11))
                            Text(tab.label)
                                .font(.system(size: 12, weight: activeTab == tab ? .semibold : .regular))
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(activeTab == tab ? Color(nsColor: .controlBackgroundColor) : Color.clear)
                        .foregroundStyle(activeTab == tab ? Color.primary : Color.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .shadow(color: activeTab == tab ? .black.opacity(0.08) : .clear, radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.12), value: activeTab)
                }
            }
            .padding(3)
            .background(Color.primary.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Spacer()

            // Veraltete DB
            if databaseOutdated {
                Button { showSettings = true } label: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.orange)
                }
                .buttonStyle(.plain)
                .help(String(localized: "db.outdated_hint"))
            }

            // Titel vorschlagen
            Button { vm.suggestRandom() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 12, weight: .semibold))
                    Text(String(localized: "action.suggest_now"))
                        .font(.system(size: 12, weight: .semibold))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    vm.hasDatabase && vm.filteredCount > 0
                        ? Color.accentColor
                        : Color.secondary.opacity(0.1)
                )
                .foregroundStyle(
                    vm.hasDatabase && vm.filteredCount > 0 ? Color.white : Color.secondary
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(!vm.hasDatabase || vm.filteredCount == 0)
            .keyboardShortcut("r", modifiers: .command)

            // Filter-Button mit Badge
            Button { showFilter.toggle() } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(activeFilterCount > 0 ? Color.accentColor : Color.secondary)

                    if activeFilterCount > 0 {
                        Text("\(activeFilterCount)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 13, height: 13)
                            .background(Color.accentColor)
                            .clipShape(Circle())
                            .offset(x: 5, y: -4)
                    }
                }
                .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showFilter, arrowEdge: .bottom) {
                FilterPopoverContent(vm: vm)
            }

            // Einstellungen
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(",", modifiers: .command)
        }
        .padding(.leading, 84)
        .padding(.trailing, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Content

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

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)

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

// MARK: - Window configurator

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
