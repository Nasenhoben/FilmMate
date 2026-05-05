import Foundation

actor TMDBService {
    static let shared = TMDBService()

    private let baseURL = "https://api.themoviedb.org/3"
    private let minimumVotes = 20
    private let pagesPerRatingSort    = 15   // 15 × 20 = 300 top-bewertete Titel pro Anbieter
    private let pagesPerDateSort      = 15   // 15 × 20 = 300 neueste Titel pro Anbieter
    private let pagesPerPopularSort   = 15   // 15 × 20 = 300 populärste Titel pro Anbieter
    private let maxConcurrentRequests = 2    // parallele Requests

    private var apiKey: String {
        UserDefaults.standard.string(forKey: "tmdb_api_key") ?? ""
    }

    // MARK: - API key validation

    func validateAPIKey(_ key: String) async -> Bool {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return false }
        var components = URLComponents(string: "\(baseURL)/authentication")!
        components.queryItems = [URLQueryItem(name: "api_key", value: trimmedKey)]
        guard let url = components.url else { return false }
        do {
            let (_, response) = try await fetchData(from: url)
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
        guard await validateAPIKey(apiKey) else { throw TMDBError.invalidAPIKey }

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

        for provider in providers {
            merge(try await fetchAllPages(for: provider, sortBy: "vote_average.desc",
                                          pages: pagesPerRatingSort, counter: counter))
            merge(try await fetchAllPages(for: provider, sortBy: "primary_release_date.desc",
                                          pages: pagesPerDateSort, counter: counter))
            merge(try await fetchAllPages(for: provider, sortBy: "popularity.desc",
                                          pages: pagesPerPopularSort, counter: counter))
        }

        await MainActor.run { progressCallback(1.0, String(localized: "progress.done")) }
        return Array(movieMap.values).sorted { $0.voteAverage > $1.voteAverage }
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

            try await Task.sleep(nanoseconds: 350_000_000)
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

        let (data, response) = try await fetchData(from: components.url!)
        if isPageLimitResponse(data: data, response: response) {
            return TMDBMovieResponse(results: [], totalPages: max(page - 1, 1), totalResults: 0)
        }
        try validate(response: response, data: data)

        return try JSONDecoder().decode(TMDBMovieResponse.self, from: data)
    }

    // MARK: - Series fetch

    func fetchSeriesWithProviders(
        progressCallback: @escaping @Sendable (Double, String) -> Void
    ) async throws -> [Movie] {
        guard !apiKey.isEmpty else { throw TMDBError.missingAPIKey }
        guard await validateAPIKey(apiKey) else { throw TMDBError.invalidAPIKey }

        await MainActor.run { progressCallback(0.0, String(localized: "progress.fetching_series")) }

        let providers = StreamingProvider.allCases
        let seriesPagesRating  = 15
        let seriesPagesDate    = 15
        let seriesPagesPopular = 15
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

        for provider in providers {
            merge(try await fetchAllTVPages(for: provider, sortBy: "vote_average.desc",
                                            pages: seriesPagesRating, counter: counter))
            merge(try await fetchAllTVPages(for: provider, sortBy: "first_air_date.desc",
                                            pages: seriesPagesDate, counter: counter))
            merge(try await fetchAllTVPages(for: provider, sortBy: "popularity.desc",
                                            pages: seriesPagesPopular, counter: counter))
        }

        await MainActor.run { progressCallback(1.0, String(localized: "progress.done")) }
        return Array(seriesMap.values).sorted { $0.voteAverage > $1.voteAverage }
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
            try await Task.sleep(nanoseconds: 350_000_000)
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

        let (data, response) = try await fetchData(from: components.url!)
        if isPageLimitResponse(data: data, response: response) {
            return TMDBTVResponse(results: [], totalPages: max(page - 1, 1), totalResults: 0)
        }
        try validate(response: response, data: data)
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
        let (data, response) = try await fetchData(from: components.url!)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(TMDBSeriesDetailResponse.self, from: data)
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
        let (data, response) = try await fetchData(from: components.url!)
        try validate(response: response, data: data)
        return try JSONDecoder().decode(TMDBMovieDetailResponse.self, from: data)
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
              let (data, response) = try? await fetchData(from: url),
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
        let (data, response) = try await fetchData(from: components.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        struct R: Codable { let runtime: Int? }
        return (try? JSONDecoder().decode(R.self, from: data))?.runtime
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDBError.invalidResponse(statusCode: nil, message: nil)
        }
        guard httpResponse.statusCode == 200 else {
            let message = try? JSONDecoder().decode(TMDBAPIErrorResponse.self, from: data).statusMessage
            if httpResponse.statusCode == 401 {
                throw TMDBError.invalidAPIKey
            }
            throw TMDBError.invalidResponse(statusCode: httpResponse.statusCode, message: message)
        }
    }

    private func fetchData(from url: URL) async throws -> (Data, URLResponse) {
        var attempt = 0

        while true {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 429,
                  attempt < 6
            else {
                return (data, response)
            }

            attempt += 1
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap(Double.init) ?? Double(attempt * 2)
            let delay = min(max(retryAfter, 1), 20)
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }

    private func isPageLimitResponse(data: Data, response: URLResponse) -> Bool {
        guard (response as? HTTPURLResponse)?.statusCode == 422,
              let message = try? JSONDecoder().decode(TMDBAPIErrorResponse.self, from: data).statusMessage
        else { return false }
        return message.localizedCaseInsensitiveContains("page")
    }
}

private struct TMDBAPIErrorResponse: Codable {
    let statusMessage: String

    enum CodingKeys: String, CodingKey {
        case statusMessage = "status_message"
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
    case invalidAPIKey
    case invalidResponse(statusCode: Int?, message: String?)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:   return String(localized: "error.missing_api_key")
        case .invalidAPIKey:   return String(localized: "error.invalid_api_key")
        case .invalidResponse(let statusCode, let message):
            let fallback = String(localized: "error.invalid_response")
            guard let statusCode else { return fallback }
            if let message, !message.isEmpty {
                return "\(fallback) (HTTP \(statusCode): \(message))"
            }
            return "\(fallback) (HTTP \(statusCode))"
        case .decodingError:   return String(localized: "error.decoding_error")
        }
    }
}
