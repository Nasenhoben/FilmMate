import Foundation

struct Movie: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let originalTitle: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String
    let voteAverage: Double
    let voteCount: Int
    let genreIds: [Int]
    var availableOn: [StreamingProvider]
    var runtime: Int?

    var genres: [Genre] {
        Genre.from(tmdbIds: genreIds)
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w342\(path)")
    }

    var backdropURL: URL? {
        guard let path = backdropPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w780\(path)")
    }

    var releaseYear: String {
        String(releaseDate.prefix(4))
    }

    var ratingFormatted: String {
        String(format: "%.1f", voteAverage)
    }

    var runtimeFormatted: String? {
        guard let runtime else { return nil }
        let h = runtime / 60
        let m = runtime % 60
        if h > 0 && m > 0 { return "\(h)h \(m)min" }
        if h > 0 { return "\(h)h" }
        return "\(m)min"
    }

    static func == (lhs: Movie, rhs: Movie) -> Bool {
        lhs.id == rhs.id
    }
}

// TMDB API response models
struct TMDBMovieResponse: Codable {
    let results: [TMDBMovie]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBMovie: Codable {
    let id: Int
    let title: String
    let originalTitle: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String
    let voteAverage: Double
    let voteCount: Int
    let genreIds: [Int]

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case originalTitle = "original_title"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case genreIds = "genre_ids"
    }

    func toMovie(providers: [StreamingProvider] = []) -> Movie {
        Movie(
            id: id,
            title: title,
            originalTitle: originalTitle,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate,
            voteAverage: voteAverage,
            voteCount: voteCount,
            genreIds: genreIds,
            availableOn: providers,
            runtime: nil
        )
    }
}

struct TMDBProvidersResponse: Codable {
    let results: [String: ProvidersByType]

    struct ProvidersByType: Codable {
        let flatrate: [ProviderEntry]?
        let rent: [ProviderEntry]?
        let buy: [ProviderEntry]?
    }

    struct ProviderEntry: Codable {
        let providerId: Int
        let providerName: String

        enum CodingKeys: String, CodingKey {
            case providerId = "provider_id"
            case providerName = "provider_name"
        }
    }
}
