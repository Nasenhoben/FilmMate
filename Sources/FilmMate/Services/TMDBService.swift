import Foundation

actor TMDBService {
    static let shared = TMDBService()

    private let baseURL = "https://api.themoviedb.org/3"
    private let minimumVotes = 20
    private let pagesPerRatingSort    = 500  // 500 × 20 = 10.000 top-bewertete Filme pro Anbieter
    private let pagesPerDateSort      = 500  // 500 × 20 = 10.000 neueste Filme pro Anbieter
    private let pagesPerPopularSort   = 500  // 500 × 20 = 10.000 populärste Filme pro Anbieter
    private let maxConcurrentRequests = 5    // parallele Requests

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
        let totalUnits = Double(providers.count * (pagesPerRatingSort + pagesPerDateSort + pagesPerPopularSort))
        let counter = ProgressCounter(total: totalUnits, callback: progressCallback)

        // Fetch all providers concurrently – three sort strategies
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
                group.addTask {
                    try await self.fetchAllPages(for: provider, sortBy: "popularity.desc",
                                                 pages: self.pagesPerPopularSort, counter: counter)
                }
            }
            for try await results in group { merge(results) }
        }

        let sorted = Array(movieMap.values).sorted { $0.voteAverage > $1.voteAverage }

        // Phase 2: Laufzeiten für die Top-2000 Filme nachladen
        let top500Ids = Array(sorted.prefix(2000).map(\.id))
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

        let firstPage = try await discoverPage(provider: provider, sortBy: sortBy, page: 1)
        results.append(contentsOf: firstPage.results.map { ($0, provider) })
        await counter.increment(by: 1)

        let pageLimit = min(pages, max(firstPage.totalPages, 1))
        guard pageLimit > 1 else { return results }

        // Fetch pages in batches to respect rate limits
        let batches = stride(from: 2, through: pageLimit, by: maxConcurrentRequests)
        for batchStart in batches {
            let batchEnd = min(batchStart + maxConcurrentRequests - 1, pageLimit)

            try await withThrowingTaskGroup(of: TMDBMovieResponse.self) { group in
                for page in batchStart...batchEnd {
                    group.addTask {
                        try await self.discoverPage(provider: provider, sortBy: sortBy, page: page)
                    }
                }

                for try await response in group {
                    for movie in response.results {
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

    private func discoverPage(provider: StreamingProvider, sortBy: String, page: Int) async throws -> TMDBMovieResponse {
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

        return try JSONDecoder().decode(TMDBMovieResponse.self, from: data)
    }

    // MARK: - Series fetch

    func fetchSeriesWithProviders(
        progressCallback: @escaping @Sendable (Double, String) -> Void
    ) async throws -> [Movie] {
        guard !apiKey.isEmpty else { throw TMDBError.missingAPIKey }

        await MainActor.run { progressCallback(0.0, String(localized: "progress.fetching_series")) }

        let providers = StreamingProvider.allCases
        let seriesPagesRating  = 500
        let seriesPagesDate    = 500
        let seriesPagesPopular = 500
        let totalUnits = Double(providers.count * (seriesPagesRating + seriesPagesDate + seriesPagesPopular))
        let counter = ProgressCounter(total: totalUnits, callback: progressCallback)

        var seriesMap: [Int: Movie] = [:]

        func merge(_ results: [(TMDBTVShow, StreamingProvider)]) {
            for (show, provider) in results {
                if var existing = seriesMap[show.id] {
                    if !existing.availableOn.contains(provider) {
                        existing.availableOn.append(provider)
                    }
                    seriesMap[show.id] = existing
                } else {
                    seriesMap[show.id] = show.toMovie(providers: [provider])
                }
            }
        }

        try await withThrowingTaskGroup(of: [(TMDBTVShow, StreamingProvider)].self) { group in
            for provider in providers {
                group.addTask {
                    try await self.fetchAllTVPages(for: provider, sortBy: "vote_average.desc",
                                                   pages: seriesPagesRating, counter: counter)
                }
                group.addTask {
                    try await self.fetchAllTVPages(for: provider, sortBy: "first_air_date.desc",
                                                   pages: seriesPagesDate, counter: counter)
                }
                group.addTask {
                    try await self.fetchAllTVPages(for: provider, sortBy: "popularity.desc",
                                                   pages: seriesPagesPopular, counter: counter)
                }
            }
            for try await results in group { merge(results) }
        }

        let sorted = Array(seriesMap.values).sorted { $0.voteAverage > $1.voteAverage }

        // Fetch episode runtimes for top 1000 series
        let top200Ids = Array(sorted.prefix(1000).map(\.id))
        await MainActor.run { progressCallback(0.99, String(localized: "progress.fetching_runtimes")) }
        let runtimes = await fetchEpisodeRuntimes(for: top200Ids)

        let series = sorted.map { s -> Movie in
            var m = s
            m.episodeRuntime = runtimes[s.id]
            return m
        }

        await MainActor.run { progressCallback(1.0, String(localized: "progress.done")) }
        return series
    }

    private func fetchAllTVPages(
        for provider: StreamingProvider,
        sortBy: String,
        pages: Int,
        counter: ProgressCounter
    ) async throws -> [(TMDBTVShow, StreamingProvider)] {
        var results: [(TMDBTVShow, StreamingProvider)] = []

        let firstPage = try await discoverTVPage(provider: provider, sortBy: sortBy, page: 1)
        results.append(contentsOf: firstPage.results.map { ($0, provider) })
        await counter.increment(by: 1)

        let pageLimit = min(pages, max(firstPage.totalPages, 1))
        guard pageLimit > 1 else { return results }

        let batches = stride(from: 2, through: pageLimit, by: maxConcurrentRequests)
        for batchStart in batches {
            let batchEnd = min(batchStart + maxConcurrentRequests - 1, pageLimit)
            try await withThrowingTaskGroup(of: TMDBTVResponse.self) { group in
                for page in batchStart...batchEnd {
                    group.addTask {
                        try await self.discoverTVPage(provider: provider, sortBy: sortBy, page: page)
                    }
                }
                for try await response in group {
                    for show in response.results { results.append((show, provider)) }
                    await counter.increment(by: 1)
                }
            }
            try await Task.sleep(nanoseconds: 150_000_000)
        }
        return results
    }

    private func discoverTVPage(provider: StreamingProvider, sortBy: String, page: Int) async throws -> TMDBTVResponse {
        var components = URLComponents(string: "\(baseURL)/discover/tv")!
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
        return try JSONDecoder().decode(TMDBTVResponse.self, from: data)
    }

    // MARK: - Series details

    func fetchSeriesDetails(seriesId: Int) async throws -> TMDBSeriesDetailResponse {
        guard !apiKey.isEmpty else { throw TMDBError.missingAPIKey }
        var components = URLComponents(string: "\(baseURL)/tv/\(seriesId)")!
        components.queryItems = [
            URLQueryItem(name: "api_key",            value: apiKey),
            URLQueryItem(name: "language",           value: language),
            URLQueryItem(name: "append_to_response", value: "credits")
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw TMDBError.invalidResponse
        }
        return try JSONDecoder().decode(TMDBSeriesDetailResponse.self, from: data)
    }

    private func fetchEpisodeRuntimes(for seriesIds: [Int]) async -> [Int: Int] {
        var runtimeMap: [Int: Int] = [:]
        let batches = stride(from: 0, to: seriesIds.count, by: maxConcurrentRequests)
        let key = apiKey
        let lang = language
        let base = baseURL

        for batchStart in batches {
            let batchEnd = min(batchStart + maxConcurrentRequests, seriesIds.count)
            let batch = Array(seriesIds[batchStart..<batchEnd])

            await withTaskGroup(of: (Int, Int?).self) { group in
                for id in batch {
                    group.addTask {
                        struct R: Codable {
                            let episodeRunTime: [Int]?
                            enum CodingKeys: String, CodingKey { case episodeRunTime = "episode_run_time" }
                        }
                        var components = URLComponents(string: "\(base)/tv/\(id)")!
                        components.queryItems = [
                            URLQueryItem(name: "api_key", value: key),
                            URLQueryItem(name: "language", value: lang)
                        ]
                        let runtime: Int? = try? await {
                            let (data, _) = try await URLSession.shared.data(from: components.url!)
                            let decoded = try JSONDecoder().decode(R.self, from: data)
                            guard let times = decoded.episodeRunTime, !times.isEmpty else { return nil }
                            return times.reduce(0, +) / times.count
                        }()
                        return (id, runtime)
                    }
                }
                for await (id, runtime) in group {
                    if let runtime { runtimeMap[id] = runtime }
                }
            }
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
        return runtimeMap
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

    // MARK: - Trailer

    func fetchTrailerKey(id: Int, isTV: Bool) async -> String? {
        // Try current language first, fall back to English
        if let key = await _fetchTrailerKey(id: id, isTV: isTV, lang: language) { return key }
        if language != "en-US" { return await _fetchTrailerKey(id: id, isTV: isTV, lang: "en-US") }
        return nil
    }

    private func _fetchTrailerKey(id: Int, isTV: Bool, lang: String) async -> String? {
        let path = isTV ? "tv" : "movie"
        var components = URLComponents(string: "\(baseURL)/\(path)/\(id)/videos")!
        components.queryItems = [
            URLQueryItem(name: "api_key",  value: apiKey),
            URLQueryItem(name: "language", value: lang)
        ]
        guard let url = components.url,
              let (data, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }

        struct VideoResult: Codable {
            let key: String
            let site: String
            let type: String
            let official: Bool?
        }
        struct VideosResponse: Codable { let results: [VideoResult] }

        guard let decoded = try? JSONDecoder().decode(VideosResponse.self, from: data) else { return nil }
        let trailers = decoded.results.filter { $0.site == "YouTube" && $0.type == "Trailer" }
        return (trailers.first(where: { $0.official == true }) ?? trailers.first)?.key
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
