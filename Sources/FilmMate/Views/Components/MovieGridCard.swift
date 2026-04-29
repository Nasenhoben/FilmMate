import SwiftUI
import AppKit

struct MovieGridCard: View {
    let movie: Movie
    @ObservedObject private var watchlist = WatchlistService.shared
    @State private var appeared = false
    @State private var hovered = false
    @State private var showDetail = false
    @State private var resolvedRuntime: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            providerBanner
            posterSection
            infoSection
            watchlistButton
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(hovered ? 0.28 : 0.18), radius: hovered ? 12 : 8, x: 0, y: hovered ? 5 : 3)
        .scaleEffect(hovered ? 1.02 : 1.0)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(duration: 0.35, bounce: 0.08)) { appeared = true }
            resolvedRuntime = movie.runtimeFormatted
            if movie.runtime == nil { fetchRuntimeIfNeeded() }
        }
        .onHover { hovered = $0 }
        .animation(.spring(duration: 0.2, bounce: 0.1), value: hovered)
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) { MovieDetailView(movie: movie) }
        .cursor(.pointingHand)
    }

    private func fetchRuntimeIfNeeded() {
        Task {
            guard let minutes = try? await TMDBService.shared.fetchRuntime(movieId: movie.id),
                  let formatted = Movie.formatRuntime(minutes) else { return }
            await MainActor.run {
                resolvedRuntime = formatted
                DatabaseService.shared.updateRuntime(movieId: movie.id, runtime: minutes)
            }
        }
    }

    // MARK: – Colored provider banner

    private var providerBanner: some View {
        HStack(spacing: 0) {
            ForEach(movie.availableOn) { provider in
                HStack(spacing: 4) {
                    Circle()
                        .fill(.white.opacity(0.8))
                        .frame(width: 5, height: 5)
                    Text(provider.name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(provider.color)
            }
        }
    }

    // MARK: – Poster with rating overlay

    private var posterSection: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: movie.posterURL) { image in
                image.resizable().aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .overlay {
                        Image(systemName: "film")
                            .font(.title2)
                            .foregroundStyle(.secondary.opacity(0.4))
                    }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipped()

            // Gradient + rating + runtime
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )

            HStack {
                // Rating
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                    Text(movie.ratingFormatted)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                // Laufzeit
                if let runtime = resolvedRuntime {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(runtime)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
        }
    }

    // MARK: – Compact info strip

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Title + year row
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(movie.title)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Text(movie.releaseYear)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .layoutPriority(-1)
            }

            // Overview
            if !movie.overview.isEmpty {
                Text(movie.overview)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Laufzeit + Genre-Emojis
            HStack(spacing: 6) {
                if let runtime = resolvedRuntime {
                    HStack(spacing: 3) {
                        Image(systemName: "clock")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                        Text(runtime)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Text("·")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                HStack(spacing: 3) {
                    ForEach(movie.genres.prefix(3)) { genre in
                        Text(genre.emoji)
                            .font(.system(size: 11))
                            .help(genre.localizedName)
                    }
                }
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
    }

    // MARK: – Watchlist button

    private var watchlistButton: some View {
        let inList = watchlist.contains(movie)
        return Button {
            watchlist.toggle(movie)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: inList ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 10, weight: .semibold))
                Text(inList ? String(localized: "watchlist.remove") : String(localized: "watchlist.add"))
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(inList ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.05))
            .foregroundStyle(inList ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: inList)
    }
}

// MARK: – Pointing hand cursor

private extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { inside in
            if inside { cursor.push() } else { NSCursor.pop() }
        }
    }
}
