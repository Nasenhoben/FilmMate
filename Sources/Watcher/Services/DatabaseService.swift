import Foundation

@MainActor
final class DatabaseService: ObservableObject {
    static let shared = DatabaseService()

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var lastUpdated: Date?

    private let storageURL: URL = {
        AppDirectories.applicationSupportDirectory().appendingPathComponent("movies.json")
    }()

    private let metaURL: URL = {
        AppDirectories.applicationSupportDirectory().appendingPathComponent("meta.json")
    }()

    private init() {
        load()
    }

    func updateRuntime(movieId: Int, runtime: Int) {
        guard let idx = movies.firstIndex(where: { $0.id == movieId }) else { return }
        movies[idx].runtime = runtime
        if let data = try? JSONEncoder().encode(movies) {
            try? data.write(to: storageURL, options: .atomicWrite)
        }
    }

    func save(_ movies: [Movie]) {
        self.movies = movies
        self.lastUpdated = Date()

        do {
            let data = try JSONEncoder().encode(movies)
            try data.write(to: storageURL, options: .atomicWrite)

            let seriesCount = movies.filter { $0.mediaType == .series }.count
            let meta = DatabaseMeta(lastUpdated: Date(), movieCount: movies.count, seriesCount: seriesCount)
            let metaData = try JSONEncoder().encode(meta)
            try metaData.write(to: metaURL, options: .atomicWrite)
        } catch {
            print("DatabaseService save error: \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        do {
            movies = try JSONDecoder().decode([Movie].self, from: data)
        } catch {
            print("⚠️ DatabaseService: Datenbank konnte nicht geladen werden – \(error)")
            print("   Datei: \(storageURL.path)")
            // Datei umbenennen statt löschen, damit keine Daten verloren gehen
            let backupURL = storageURL.deletingPathExtension().appendingPathExtension("json.bak")
            try? FileManager.default.moveItem(at: storageURL, to: backupURL)
            print("   Backup gespeichert unter: \(backupURL.path)")
        }

        if let metaData = try? Data(contentsOf: metaURL),
           let meta = try? JSONDecoder().decode(DatabaseMeta.self, from: metaData) {
            lastUpdated = meta.lastUpdated
        }
    }

    // MARK: - Query

    func filtered(
        genres: Set<Genre>,
        providers: Set<StreamingProvider>,
        minimumRating: Double = 0.0,
        runtimeFilter: RuntimeFilter = .all,
        mediaTypeFilter: MediaTypeFilter = .all
    ) -> [Movie] {
        movies.filter { movie in
            let genreMatch    = genres.isEmpty || !Set(movie.genreIds).isDisjoint(with: Set(genres.map(\.rawValue)))
            let providerMatch = providers.isEmpty || !Set(movie.availableOn).isDisjoint(with: providers)
            let ratingMatch   = movie.voteAverage >= minimumRating
            let effectiveRuntime = movie.mediaType == .series ? movie.episodeRuntime : movie.runtime
            let runtimeMatch  = runtimeFilter.matches(effectiveRuntime)
            let mediaMatch: Bool
            switch mediaTypeFilter {
            case .all:    mediaMatch = true
            case .movies: mediaMatch = movie.mediaType == .movie
            case .series: mediaMatch = movie.mediaType == .series
            }
            return genreMatch && providerMatch && ratingMatch && runtimeMatch && mediaMatch
        }
    }

    func randomMovie(
        genres: Set<Genre>,
        providers: Set<StreamingProvider>
    ) -> Movie? {
        filtered(genres: genres, providers: providers).randomElement()
    }

    func moviesByGenre() -> [(Genre, [Movie])] {
        Genre.allCases.compactMap { genre in
            let matching = movies.filter { movie in
                movie.genreIds.contains(genre.rawValue)
            }
            return matching.isEmpty ? nil : (genre, matching)
        }
    }

    var totalCount: Int { movies.count }

    var isEmpty: Bool { movies.isEmpty }
}

private struct DatabaseMeta: Codable {
    let lastUpdated: Date
    let movieCount: Int
    var seriesCount: Int = 0
}
