import SwiftUI
import AppKit

// MARK: - Filter Popover Content

struct FilterPopoverContent: View {
    @ObservedObject var vm: MovieViewModel

    private var hasActiveFilters: Bool {
        vm.mediaTypeFilter != .all || !vm.selectedProviders.isEmpty ||
        vm.minimumRating > 0 || vm.runtimeFilter != .all || !vm.selectedGenres.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            contentTypeSection
            Divider().padding(.horizontal, 12)
            providerSection
            Divider().padding(.horizontal, 12)
            filterSection
            Divider().padding(.horizontal, 12)
            genreSection

            if hasActiveFilters {
                Divider().padding(.horizontal, 12)
                Button { vm.clearFilters() } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "xmark.circle")
                            .font(.caption)
                        Text(String(localized: "filter.clear"))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(width: 260)
        .animation(.spring(duration: 0.25), value: hasActiveFilters)
    }

    // MARK: – Inhaltstyp

    private var contentTypeSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            sectionHeader("filter.content_type")
            HStack(spacing: 4) {
                ForEach(MediaTypeFilter.allCases) { filter in
                    let isSelected = vm.mediaTypeFilter == filter
                    Button {
                        vm.setMediaType(filter)
                    } label: {
                        Text(filter.label)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06))
                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.12), value: isSelected)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: – Streaminganbieter

    private var providerSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            sectionHeader("filter.providers")
            VStack(spacing: 1) {
                ForEach(vm.visibleProviders) { provider in
                    ProviderToggleRow(
                        provider: provider,
                        isSelected: vm.selectedProviders.contains(provider)
                    ) {
                        vm.toggleProvider(provider)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: – Bewertung + Laufzeit

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
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
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.12), value: isSelected)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
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
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 5)
                                .background(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06))
                                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .animation(.easeInOut(duration: 0.12), value: isSelected)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    // MARK: – Genres

    private var genreSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            sectionHeader("filter.genres")
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)],
                spacing: 4
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
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 12)
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
                Circle()
                    .fill(provider.color)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().strokeBorder(provider.color.opacity(0.3), lineWidth: 1).scaleEffect(1.6))

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
        Button {
            let path = movie.mediaType == .series ? "tv" : "movie"
            if let url = URL(string: "https://www.themoviedb.org/\(path)/\(movie.id)") {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 6) {
                Text(movie.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                if !movie.availableOn.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(movie.availableOn) { provider in
                            Text(provider.initial)
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 15, height: 15)
                                .background(provider.color)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .help(provider.name)
                        }
                    }
                }

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
            .padding(.vertical, 5)
            .background(hovered ? Color.primary.opacity(0.05) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
            HStack(spacing: 3) {
                Text(genre.emoji)
                    .font(.system(size: 10))
                Text(genre.localizedName)
                    .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(
                isSelected
                    ? genre.color.opacity(0.22)
                    : (hovered ? Color.primary.opacity(0.05) : Color.clear)
            )
            .foregroundStyle(isSelected ? genre.color : Color.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6)
                .strokeBorder(isSelected ? genre.color.opacity(0.65) : Color.clear, lineWidth: 1.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
        .animation(.easeInOut(duration: 0.12), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: hovered)
    }
}
