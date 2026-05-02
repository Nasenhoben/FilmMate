import SwiftUI

struct WatchlistOverviewView: View {
    @ObservedObject private var watchlist = WatchlistService.shared

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    var body: some View {
        Group {
            if watchlist.movies.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(
                                Array(watchlist.movies.enumerated()),
                                id: \.element.id
                            ) { index, movie in
                                MovieGridCard(movie: movie)
                                    .animation(
                                        Animation.spring(duration: 0.38, bounce: 0.08)
                                            .delay(Double(index) * 0.04),
                                        value: watchlist.movies.map(\.id)
                                    )
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(duration: 0.3), value: watchlist.movies.count)
    }

    // MARK: – Header

    private var header: some View {
        HStack(spacing: 8) {
            Text(String(localized: "watchlist.overview.title"))
                .font(.headline)

            Text("\(watchlist.movies.count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.accentColor)
                .clipShape(Capsule())

            Spacer()

            Button { watchlist.removeAll() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text(String(localized: "watchlist.remove_all"))
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: – Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 90, height: 90)
                Image(systemName: "bookmark")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.accentColor.opacity(0.5))
            }
            VStack(spacing: 8) {
                Text(String(localized: "watchlist.empty_title"))
                    .font(.title3).fontWeight(.bold)
                Text(String(localized: "watchlist.empty_subtitle"))
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
