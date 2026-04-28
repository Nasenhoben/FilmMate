import Foundation

@MainActor
final class DatabaseService: ObservableObject {
    static let shared = DatabaseService()

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var lastUpdated: Date?

    private let storageURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("FilmMate", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("movies.json")
    }()

    private let metaURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("FilmMate/meta.json")
    }()

    private init() {
        load()
    }

    func save(_ movies: [Movie]) {
        self.movies = movies
        self.lastUpdated = Date()

        do {
            let data = try JSONEncoder().encode(movies)
            try data.write(to: storageURL, options: .atomicWrite)

            let meta = DatabaseMeta(lastUpdated: Date(), movieCount: movies.count)
            let metaData = try JSONEncoder().encode(meta)
            try metaData.write(to: metaURL, options: .atomicWrite)
        } catch {
            print("DatabaseService save error: \(error)")
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL) else { return }
        if let decoded = try? JSONDecoder().decode([Movie].self, from: data) {
            movies = decoded
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
        runtimeFilter: RuntimeFilter = .all
    ) -> [Movie] {
        movies.filter { movie in
            let genreMatch    = genres.isEmpty || !Set(movie.genreIds).isDisjoint(with: Set(genres.map(\.rawValue)))
            let providerMatch = providers.isEmpty || !Set(movie.availableOn).isDisjoint(with: providers)
            let ratingMatch   = movie.voteAverage >= minimumRating
            let runtimeMatch  = runtimeFilter.matches(movie.runtime)
            return genreMatch && providerMatch && ratingMatch && runtimeMatch
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
}
