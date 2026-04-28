import SwiftUI
import AppKit

struct FilterSidebarView: View {
    @ObservedObject var vm: MovieViewModel
    @ObservedObject private var watchlist = WatchlistService.shared
    let onSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    providerSection
                    Divider().padding(.horizontal, 12)
                    watchlistSection
                    Divider().padding(.horizontal, 12)
                    genreSection
                }
            }
            .scrollIndicators(.never)
            bottomBar
        }
        .frame(width: 280)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    // MARK: – Streaming Providers

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("filter.providers")

            VStack(spacing: 2) {
                ForEach(StreamingProvider.allCases) { provider in
                    ProviderToggleRow(
                        provider: provider,
                        isSelected: vm.selectedProviders.contains(provider)
                    ) {
                        vm.toggleProvider(provider)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: – Watchlist

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                sectionHeader("watchlist.title")
                Spacer()
                if !watchlist.movies.isEmpty {
                    HStack(spacing: 6) {
                        Text("\(watchlist.movies.count)")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .clipShape(Capsule())

                        Button {
                            watchlist.removeAll()
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help(String(localized: "watchlist.remove_all"))
                    }
                }
            }

            if watchlist.movies.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text(String(localized: "watchlist.empty"))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            } else {
                VStack(spacing: 2) {
                    ForEach(watchlist.movies.prefix(5)) { movie in
                        WatchlistRowItem(movie: movie) {
                            watchlist.remove(movie)
                        }
                    }
                }

                if watchlist.movies.count > 5 {
                    Text(String(format: String(localized: "watchlist.more"), watchlist.movies.count - 5))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .animation(.spring(duration: 0.25), value: watchlist.movies.count)
    }

    // MARK: – Genres

    private var genreSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("filter.genres")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 5), GridItem(.flexible(), spacing: 5)],
                spacing: 5
            ) {
                ForEach(Genre.allCases) { genre in
                    GenreToggleTile(
                        genre: genre,
                        isSelected: vm.selectedGenres.contains(genre)
                    ) {
                        vm.toggleGenre(genre)
                    }
                }
            }

            // Clear-Link wenn aktive Filter
            if !vm.selectedGenres.isEmpty || !vm.selectedProviders.isEmpty {
                Button { vm.clearFilters() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                            .font(.caption)
                        Text(String(localized: "filter.clear"))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .animation(.spring(duration: 0.25), value: vm.selectedGenres.isEmpty && vm.selectedProviders.isEmpty)
    }

    // MARK: – Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 8) {
            Divider()

            Button { vm.suggestRandom() } label: {
                HStack(spacing: 7) {
                    Image(systemName: "shuffle")
                        .font(.callout)
                    Text(String(localized: "action.suggest_now"))
                        .font(.callout)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    vm.hasDatabase && vm.filteredCount > 0
                        ? Color.accentColor
                        : Color.secondary.opacity(0.12)
                )
                .foregroundStyle(
                    vm.hasDatabase && vm.filteredCount > 0 ? Color.white : Color.secondary
                )
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .disabled(!vm.hasDatabase || vm.filteredCount == 0)
            .keyboardShortcut("r", modifiers: .command)

            Button(action: onSettings) {
                HStack(spacing: 6) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 12))
                    Text(String(localized: "action.settings"))
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(Color.primary.opacity(0.07))
                .foregroundStyle(Color.primary.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(",", modifiers: .command)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 12)
        .padding(.top, 6)
    }

    // MARK: – Helper

    private func sectionHeader(_ key: String) -> some View {
        Text(String(localized: String.LocalizationValue(key)).uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.secondary)
            .kerning(0.8)
    }
}

// MARK: – Provider toggle row

struct ProviderToggleRow: View {
    let provider: StreamingProvider
    let isSelected: Bool
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                // Color indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(provider.color)
                    .frame(width: 3, height: 22)

                Text(provider.name)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(provider.color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(
                isSelected
                    ? provider.color.opacity(0.1)
                    : (hovered ? Color.primary.opacity(0.05) : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: hovered)
    }
}

// MARK: – Watchlist row item

struct WatchlistRowItem: View {
    let movie: Movie
    let onRemove: () -> Void
    @State private var hovered = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 9))
                .foregroundStyle(Color.accentColor.opacity(0.7))

            Button {
                if let url = URL(string: "https://www.themoviedb.org/movie/\(movie.id)") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Text(movie.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            if hovered {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(hovered ? Color.primary.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .contentShape(Rectangle())
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.1), value: hovered)
    }
}

// MARK: – Genre toggle tile

struct GenreToggleTile: View {
    let genre: Genre
    let isSelected: Bool
    let action: () -> Void
    @State private var hovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(genre.emoji)
                    .font(.system(size: 11))
                Text(genre.localizedName)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                    .lineLimit(1)
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(genre.color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 5)
            .padding(.vertical, 5)
            .background(
                isSelected
                    ? genre.color.opacity(0.22)
                    : (hovered ? Color.primary.opacity(0.05) : Color.clear)
            )
            .foregroundStyle(isSelected ? genre.color : Color.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isSelected ? genre.color.opacity(0.65) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: hovered)
    }
}
