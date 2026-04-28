import SwiftUI
import AppKit

struct MovieDetailView: View {
    let movie: Movie
    @State private var details: TMDBMovieDetailResponse?
    @State private var isLoading = true
    @ObservedObject private var watchlist = WatchlistService.shared
    @Environment(\.dismiss) private var dismiss

    private var effectiveRuntime: Int? { details?.runtime ?? movie.runtime }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection
                    Divider()
                    overviewSection
                    if isLoading {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    } else {
                        castSection
                    }
                    tmdbButton
                }
                .padding(24)
            }
        }
        .frame(width: 640, height: 580)
        .task {
            details = try? await TMDBService.shared.fetchMovieDetails(movieId: movie.id)
            isLoading = false
        }
    }

    // MARK: – Header

    private var header: some View {
        HStack {
            Text(movie.title)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    // MARK: – Hero (Poster + Basisinfos)

    private var heroSection: some View {
        HStack(alignment: .top, spacing: 20) {
            // Poster
            AsyncImage(url: movie.posterURL) { image in
                image.resizable().aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .overlay { Image(systemName: "film").font(.title).foregroundStyle(.secondary.opacity(0.4)) }
            }
            .frame(width: 130, height: 195)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.25), radius: 10, y: 4)

            // Infos
            VStack(alignment: .leading, spacing: 10) {
                // Titel + Jahr
                VStack(alignment: .leading, spacing: 2) {
                    Text(movie.title)
                        .font(.title3).fontWeight(.bold)
                        .lineLimit(3)
                    Text(movie.releaseYear)
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                // Bewertung + Laufzeit
                HStack(spacing: 12) {
                    Label(movie.ratingFormatted, systemImage: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.yellow)

                    if let rt = effectiveRuntime.flatMap({ Movie.formatRuntime($0) }) {
                        Label(rt, systemImage: "clock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                // Regisseur
                if let director = details?.director {
                    Label(director, systemImage: "video.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Genres
                FlowLayout(spacing: 5) {
                    ForEach(movie.genres) { genre in
                        HStack(spacing: 4) {
                            Text(genre.emoji).font(.system(size: 12))
                            Text(genre.localizedName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(genre.color)
                        }
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(genre.color.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }

                // Streaming-Anbieter
                if !movie.availableOn.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(movie.availableOn) { provider in
                            Text(provider.name)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(provider.color)
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer(minLength: 0)

                // Watchlist-Button
                let inList = watchlist.contains(movie)
                Button { watchlist.toggle(movie) } label: {
                    Label(
                        inList ? String(localized: "watchlist.remove") : String(localized: "watchlist.add"),
                        systemImage: inList ? "bookmark.fill" : "bookmark"
                    )
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(inList ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.06))
                    .foregroundStyle(inList ? Color.accentColor : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: inList)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: – Inhaltsangabe

    private var overviewSection: some View {
        Group {
            if !movie.overview.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("detail.overview")
                    Text(movie.overview)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: – Besetzung

    @ViewBuilder
    private var castSection: some View {
        if let cast = details?.topCast, !cast.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("detail.cast")
                HStack(spacing: 12) {
                    ForEach(cast) { member in
                        VStack(spacing: 5) {
                            AsyncImage(url: member.profileURL) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.secondary.opacity(0.15))
                                    .overlay { Image(systemName: "person.fill").foregroundStyle(.secondary.opacity(0.4)) }
                            }
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())

                            Text(member.name)
                                .font(.system(size: 10, weight: .semibold))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                        }
                    }
                }
            }
        }
    }

    // MARK: – TMDB-Link

    private var tmdbButton: some View {
        Button {
            if let url = URL(string: "https://www.themoviedb.org/movie/\(movie.id)") {
                NSWorkspace.shared.open(url)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.right.square")
                Text(String(localized: "detail.open_tmdb"))
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(Color.primary.opacity(0.06))
            .foregroundStyle(Color.primary.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    // MARK: – Hilfsmethode

    private func sectionLabel(_ key: String) -> some View {
        Text(String(localized: String.LocalizationValue(key)).uppercased())
            .font(.system(size: 9, weight: .heavy))
            .foregroundStyle(.secondary)
            .kerning(0.8)
    }
}

// MARK: – Laufzeit formatieren (statisch, für Detail-View nutzbar)

extension Movie {
    static func formatRuntime(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h > 0 && m > 0 { return "\(h)h \(m)min" }
        if h > 0 { return "\(h)h" }
        return "\(m)min"
    }
}
