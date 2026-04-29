import SwiftUI
import AppKit

struct FilterSidebarView: View {
    @ObservedObject var vm: MovieViewModel
    @ObservedObject private var watchlist = WatchlistService.shared
    let onSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Platzhalter für die Ampel-Buttons der Titelleiste
            Color.clear.frame(height: 8)

            ScrollView {
                VStack(spacing: 0) {
                    providerSection
                    Divider().padding(.horizontal, 12)
                    ratingSection
                    Divider().padding(.horizontal, 12)
                    runtimeSection
                    Divider().padding(.horizontal, 12)
                    watchlistSection
                    Divider().padding(.horizontal, 12)
                    genreSection
                }
            }
            .scrollIndicators(.never)
            bottomBar
        }
        .frame(width: 240)
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
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // MARK: – Bewertungs-Filter

    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("filter.rating")

            HStack(spacing: 4) {
                ForEach([0.0, 6.0, 7.0, 8.0], id: \.self) { rating in
                    let isSelected = vm.minimumRating == rating
                    Button {
                        vm.minimumRating = rating
                        vm.suggestedMovies = []
                    } label: {
                        Text(rating == 0 ? String(localized: "filter.rating.all") : "\(Int(rating))+")
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06))
                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.12), value: isSelected)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: – Laufzeit-Filter

    private var runtimeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("filter.runtime")

            HStack(spacing: 4) {
                ForEach(RuntimeFilter.allCases) { filter in
                    let isSelected = vm.runtimeFilter == filter
                    Button {
                        vm.runtimeFilter = filter
                        vm.suggestedMovies = []
                    } label: {
                        Text(filter.label)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06))
                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.12), value: isSelected)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 12)
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
            if !vm.selectedGenres.isEmpty || !vm.selectedProviders.isEmpty
                || vm.minimumRating > 0 || vm.runtimeFilter != .all {
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

    private var databaseOutdated: Bool {
        guard let lastUpdated = DatabaseService.shared.lastUpdated else { return false }
        return Date().timeIntervalSince(lastUpdated) > 14 * 24 * 3600
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            Divider()

            // Hinweis wenn DB älter als 14 Tage
            if databaseOutdated {
                Button(action: onSettings) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 12))
                        Text(String(localized: "db.outdated_hint"))
                            .font(.system(size: 11, weight: .medium))
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.orange.opacity(0.15))
                    .foregroundStyle(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

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
            .font(.system(size: 10, weight: .heavy))
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
            HStack(spacing: 9) {
                // Runder Farb-Badge
                Circle()
                    .fill(provider.color)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .strokeBorder(provider.color.opacity(0.3), lineWidth: 1)
                            .scaleEffect(1.6)
                    )

                Text(provider.name)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(provider.color)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                isSelected
                    ? provider.color.opacity(0.12)
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
