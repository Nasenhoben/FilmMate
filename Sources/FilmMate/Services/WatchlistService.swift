import Foundation

@MainActor
final class WatchlistService: ObservableObject {
    static let shared = WatchlistService()

    @Published private(set) var movies: [Movie] = []

    private let storageURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("FilmMate", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("watchlist.json")
    }()

    private init() { load() }

    // MARK: - Public API

    func contains(_ movie: Movie) -> Bool {
        movies.contains { $0.identityKey == movie.identityKey }
    }

    func toggle(_ movie: Movie) {
        if contains(movie) { remove(movie) } else { add(movie) }
    }

    func add(_ movie: Movie) {
        guard !contains(movie) else { return }
        movies.insert(movie, at: 0)
        save()
    }

    func remove(_ movie: Movie) {
        movies.removeAll { $0.identityKey == movie.identityKey }
        save()
    }

    func removeAll() {
        movies.removeAll()
        save()
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(movies) {
            try? data.write(to: storageURL, options: .atomicWrite)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let decoded = try? JSONDecoder().decode([Movie].self, from: data) else { return }
        movies = decoded
    }
}
