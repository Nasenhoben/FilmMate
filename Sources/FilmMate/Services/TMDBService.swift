import Foundation

actor TMDBService {
    static let shared = TMDBService()

    private let baseURL = "https://api.themoviedb.org/3"
    private let minimumVotes = 50
    private let pagesPerRatingSort = 40     // 40 × 20 = 800 top-bewertete Filme pro Anbieter
    private let pagesPerDateSort   = 10     // 10 × 20 = 200 neueste Filme pro Anbieter
    private let maxConcurrentRequests = 5   // parallele Requests

    private var apiKey: String {
        KeychainService.shared.retrieve() ?? ""
    }

    // MARK: - API key validation

    func validateAPIKey(_ key: String) async -> Bool {
        var components = URLComponents(string: "\(baseURL)/authentication")!
        components.queryItems = [URLQueryItem(name: "api_key", value: key)]
        guard let url = components.url else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    private var language: String {
        UserDefaults.standard.string(forKey: "app_language") ?? "de-DE"
    }

    // MARK: - Public entry point

    func fetchMoviesWithProviders(
        progressCallback: @escaping @Sendable (Double, String) -> Void
    ) async throws -> [Movie] {
        guard !apiKey.isEmpty else { throw TMDBError.missingAPIKey }

        await MainActor.run { progressCallback(0.0, String(localized: "progress.fetching_movies")) }

        let providers = StreamingProvider.allCases
        let totalUnits = Double(providers.count * (pagesPerRatingSort + pagesPerDateSort))
        let counter = ProgressCounter(total: totalUnits, callback: progressCallback)

        // Fetch all providers concurrently – both sort strategies
        var movieMap: [Int: Movie] = [:]

        func merge(_ results: [(TMDBMovie, StreamingProvider)]) {
            for (tmdbMovie, provider) in results {
                if var existing = movieMap[tmdbMovie.id] {
                    if !existing.availableOn.contains(provider) {
                        existing.availableOn.append(provider)
                    }
                    movieMap[tmdbMovie.id] = existing
                } else {
                    movieMap[tmdbMovie.id] = tmdbMovie.toMovie(providers: [provider])
                }
            }
        }

        try await withThrowingTaskGroup(of: [(TMDBMovie, StreamingProvider)].self) { group in
            for provider in providers {
                group.addTask {
                    try await self.fetchAllPages(for: provider, sortBy: "vote_average.desc",
                                                 pages: self.pagesPerRatingSort, counter: counter)
                }
                group.addTask {
                    try await self.fetchAllPages(for: provider, sortBy: "primary_release_date.desc",
                                                 pages: self.pagesPerDateSort, counter: counter)
                }
            }
            for try await results in group { merge(results) }
        }

        let sorted = Array(movieMap.values).sorted { $0.voteAverage > $1.voteAverage }

        // Phase 2: Laufzeiten für die Top-500 Filme nachladen
        let top500Ids = Array(sorted.prefix(500).map(\.id))
        await MainActor.run { progressCallback(0.99, String(localized: "progress.fetching_runtimes")) }
        let runtimes = await fetchRuntimes(for: top500Ids)

        let movies = sorted.map { movie -> Movie in
            var m = movie
            m.runtime = runtimes[movie.id]
            return m
        }

        await MainActor.run { progressCallback(1.0, String(localized: "progress.done")) }
        return movies
    }

    // MARK: - Fetch all pages for one provider

    private func fetchAllPages(
        for provider: StreamingProvider,
        sortBy: String,
        pages: Int,
        counter: ProgressCounter
    ) async throws -> [(TMDBMovie, StreamingProvider)] {
        var results: [(TMDBMovie, StreamingProvider)] = []

        // Fetch pages in batches to respect rate limits
        let batches = stride(from: 1, through: pages, by: maxConcurrentRequests)

        for batchStart in batches {
            let batchEnd = min(batchStart + maxConcurrentRequests - 1, pages)

            try await withThrowingTaskGroup(of: [TMDBMovie].self) { group in
                for page in batchStart...batchEnd {
                    group.addTask {
                        try await self.discoverPage(provider: provider, sortBy: sortBy, page: page)
                    }
                }

                for try await movies in group {
                    for movie in movies {
                        results.append((movie, provider))
                    }
                    await counter.increment(by: 1)
                }
            }

            // Brief pause between batches to stay within TMDB rate limit (~40 req/s)
            try await Task.sleep(nanoseconds: 150_000_000)
        }

        return results
    }

    // MARK: - Single discover page

    private func discoverPage(provider: StreamingProvider, sortBy: String, page: Int) async throws -> [TMDBMovie] {
        var components = URLComponents(string: "\(baseURL)/discover/movie")!
        components.queryItems = [
            URLQueryItem(name: "api_key",              value: apiKey),
            URLQueryItem(name: "language",             value: language),
            URLQueryItem(name: "sort_by",              value: sortBy),
            URLQueryItem(name: "vote_count.gte",       value: "\(minimumVotes)"),
            URLQueryItem(name: "with_watch_providers", value: "\(provider.rawValue)"),
            URLQueryItem(name: "watch_region",         value: "DE"),
            URLQueryItem(name: "page",                 value: "\(page)")
        ]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw TMDBError.invalidResponse
        }

        return try JSONDecoder().decode(TMDBMovieResponse.self, from: data).results
    }

    // MARK: - Film-Details (Besetzung, Regisseur, Laufzeit)

    func fetchMovieDetails(movieId: Int) async throws -> TMDBMovieDetailResponse {
        guard !apiKey.isEmpty else { throw TMDBError.missingAPIKey }
        var components = URLComponents(string: "\(baseURL)/movie/\(movieId)")!
        components.queryItems = [
            URLQueryItem(name: "api_key",             value: apiKey),
            URLQueryItem(name: "language",            value: language),
            URLQueryItem(name: "append_to_response",  value: "credits")
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw TMDBError.invalidResponse
        }
        return try JSONDecoder().decode(TMDBMovieDetailResponse.self, from: data)
    }

    // MARK: - Laufzeit-Batch-Fetch

    private func fetchRuntimes(for movieIds: [Int]) async -> [Int: Int] {
        var runtimeMap: [Int: Int] = [:]
        let batches = stride(from: 0, to: movieIds.count, by: maxConcurrentRequests)

        for batchStart in batches {
            let batchEnd = min(batchStart + maxConcurrentRequests, movieIds.count)
            let batch = Array(movieIds[batchStart..<batchEnd])

            await withTaskGroup(of: (Int, Int?).self) { group in
                for id in batch {
                    group.addTask { (id, try? await self.fetchRuntimeOnly(movieId: id)) }
                }
                for await (id, runtime) in group {
                    if let runtime { runtimeMap[id] = runtime }
                }
            }
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
        return runtimeMap
    }

    func fetchRuntime(movieId: Int) async throws -> Int? {
        try await fetchRuntimeOnly(movieId: movieId)
    }

    private func fetchRuntimeOnly(movieId: Int) async throws -> Int? {
        var components = URLComponents(string: "\(baseURL)/movie/\(movieId)")!
        components.queryItems = [
            URLQueryItem(name: "api_key",  value: apiKey),
            URLQueryItem(name: "language", value: language)
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        struct R: Codable { let runtime: Int? }
        return (try? JSONDecoder().decode(R.self, from: data))?.runtime
    }
}

// MARK: - Thread-safe progress counter

private actor ProgressCounter {
    private var completed: Double = 0
    private let total: Double
    private let callback: @Sendable (Double, String) -> Void

    init(total: Double, callback: @escaping @Sendable (Double, String) -> Void) {
        self.total = total
        self.callback = callback
    }

    func increment(by amount: Double = 1) async {
        completed += amount
        let progress = min(completed / total, 0.98)
        let cb = callback
        await MainActor.run {
            cb(progress, String(localized: "progress.checking_providers"))
        }
    }
}

// MARK: - Errors

enum TMDBError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case decodingError

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:   return String(localized: "error.missing_api_key")
        case .invalidResponse: return String(localized: "error.invalid_response")
        case .decodingError:   return String(localized: "error.decoding_error")
        }
    }
}
