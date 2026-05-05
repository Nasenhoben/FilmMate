import SwiftUI

// MARK: - Cinematic suggestion card (main feature)

struct MovieSuggestionCard: View {
    let movie: Movie
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            backdropHero
            detailStrip
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 8)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(duration: 0.45, bounce: 0.1)) { appeared = true }
        }
        .id(movie.identityKey)
    }

    // MARK: Backdrop hero

    private var backdropHero: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Backdrop image
                AsyncImage(url: movie.backdropURL ?? movie.posterURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color.indigo.opacity(0.5), Color.purple.opacity(0.3)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .overlay {
                            Image(systemName: "film.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                }
                .frame(width: geo.size.width, height: 280)
                .clipped()

                // Gradient overlay for readability
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.15), location: 0.4),
                        .init(color: .black.opacity(0.85), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Poster + title overlay
                HStack(alignment: .bottom, spacing: 16) {
                    // Floating poster
                    AsyncImage(url: movie.posterURL) { image in
                        image
                            .resizable()
                            .aspectRatio(2/3, contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.secondary.opacity(0.3))
                    }
                    .frame(width: 90, height: 135)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 4)
                    .padding(.bottom, -30)

                    // Title block
                    VStack(alignment: .leading, spacing: 6) {
                        Text(movie.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .shadow(color: .black.opacity(0.4), radius: 4)

                        HStack(spacing: 8) {
                            Text(movie.releaseYear)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))

                            ratingBadge
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .frame(height: 280)
    }

    private var ratingBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption2)
                .foregroundStyle(.yellow)
            Text(movie.ratingFormatted)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial.opacity(0.6))
        .clipShape(Capsule())
    }

    // MARK: Detail strip below backdrop

    private var detailStrip: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Overview
            Text(movie.overview)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            // Genres – prominent row
            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "filter.genres").uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .kerning(0.8)

                FlowLayout(spacing: 6) {
                    ForEach(movie.genres) { genre in
                        HStack(spacing: 5) {
                            Text(genre.emoji)
                                .font(.system(size: 14))
                            Text(genre.localizedName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(genre.color)
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(genre.color.opacity(0.13))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(genre.color.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }

            Divider()

            // Providers row
            HStack(spacing: 6) {
                Text(String(localized: "filter.providers").uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .kerning(0.8)
                Spacer()
                HStack(spacing: 5) {
                    ForEach(movie.availableOn) { provider in
                        ProviderDot(provider: provider)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(.background)
    }
}

// MARK: - Small grid card (not currently used in main flow but kept for future)

struct MovieCardView: View {
    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: movie.posterURL) { image in
                    image.resizable().aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.secondary.opacity(0.15))
                        .overlay { Image(systemName: "film").foregroundStyle(.secondary) }
                }
                .frame(maxWidth: .infinity).frame(height: 200).clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center, endPoint: .bottom
                )

                HStack(spacing: 3) {
                    Image(systemName: "star.fill").font(.caption2).foregroundStyle(.yellow)
                    Text(movie.ratingFormatted).font(.caption).fontWeight(.bold).foregroundStyle(.white)
                }
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(.black.opacity(0.5)).clipShape(Capsule())
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title).font(.caption).fontWeight(.semibold).lineLimit(2)
                Text(movie.releaseYear).font(.caption2).foregroundStyle(.secondary)

                HStack(spacing: 3) {
                    ForEach(movie.availableOn) { ProviderDot(provider: $0) }
                }
            }
            .padding(8)
            .background(.background)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
    }
}
