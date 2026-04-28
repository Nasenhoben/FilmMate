import SwiftUI

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
        .frame(minWidth: 910, minHeight: 520)
        .sheet(isPresented: $showSettings) {
            SettingsSheet(settings: settings, vm: vm, isPresented: $showSettings)
        }
        .preferredColorScheme(settings.colorScheme)
        .toolbar(.hidden, for: .windowToolbar)
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
    @State private var hovered = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "popcorn.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(spacing: 8) {
                Text(String(localized: "welcome.title"))
                    .font(.title2).fontWeight(.bold)
                Text(String(localized: "welcome.subtitle"))
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).frame(maxWidth: 320)
            }

            Button { vm.suggestRandom() } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shuffle")
                    Text(String(localized: "action.suggest_now"))
                }
                .font(.headline)
                .padding(.horizontal, 26).padding(.vertical, 11)
                .background(vm.filteredCount > 0 ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(vm.filteredCount > 0 ? Color.white : Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 11))
                .scaleEffect(hovered && vm.filteredCount > 0 ? 1.04 : 1.0)
                .shadow(color: vm.filteredCount > 0 ? Color.accentColor.opacity(0.3) : .clear, radius: 10, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(vm.filteredCount == 0)
            .onHover { hovered = $0 }
            .animation(.spring(duration: 0.2), value: hovered)
            .keyboardShortcut("r", modifiers: .command)

            if vm.filteredCount == 0 && vm.hasDatabase {
                Text(String(localized: "welcome.no_results"))
                    .font(.caption).foregroundStyle(.secondary)
                    .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.3), value: vm.filteredCount)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 5-card suggestion view

struct SuggestedMovieView: View {
    @ObservedObject var vm: MovieViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 5)

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
                    .keyboardShortcut("r", modifiers: .command)
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
    }
}
