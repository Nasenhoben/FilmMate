import Foundation

enum MediaType: String, Codable {
    case movie, series
}

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
    var mediaType: MediaType
    var numberOfSeasons: Int?
    var episodeRuntime: Int?

    init(id: Int, title: String, originalTitle: String, overview: String,
         posterPath: String?, backdropPath: String?, releaseDate: String,
         voteAverage: Double, voteCount: Int, genreIds: [Int],
         availableOn: [StreamingProvider], runtime: Int?,
         mediaType: MediaType = .movie, numberOfSeasons: Int? = nil, episodeRuntime: Int? = nil) {
        self.id = id
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.genreIds = genreIds
        self.availableOn = availableOn
        self.runtime = runtime
        self.mediaType = mediaType
        self.numberOfSeasons = numberOfSeasons
        self.episodeRuntime = episodeRuntime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        originalTitle = try container.decode(String.self, forKey: .originalTitle)
        overview = try container.decode(String.self, forKey: .overview)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        releaseDate = try container.decode(String.self, forKey: .releaseDate)
        voteAverage = try container.decode(Double.self, forKey: .voteAverage)
        voteCount = try container.decode(Int.self, forKey: .voteCount)
        genreIds = try container.decode([Int].self, forKey: .genreIds)
        let providerIds = try container.decode([Int].self, forKey: .availableOn)
        availableOn = providerIds.compactMap(StreamingProvider.init(rawValue:))
        runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        mediaType = try container.decodeIfPresent(MediaType.self, forKey: .mediaType) ?? .movie
        numberOfSeasons = try container.decodeIfPresent(Int.self, forKey: .numberOfSeasons)
        episodeRuntime = try container.decodeIfPresent(Int.self, forKey: .episodeRuntime)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, originalTitle, overview, posterPath, backdropPath
        case releaseDate, voteAverage, voteCount, genreIds, availableOn, runtime
        case mediaType, numberOfSeasons, episodeRuntime
    }

    var genres: [Genre] {
        Genre.from(tmdbIds: genreIds)
    }

    var identityKey: String {
        "\(mediaType.rawValue)-\(id)"
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

    static func formatRuntime(_ minutes: Int) -> String? {
        guard minutes > 0 else { return nil }
        let h = minutes / 60
        let m = minutes % 60
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
            runtime: nil,
            mediaType: .movie
        )
    }
}

struct TMDBTVResponse: Codable {
    let results: [TMDBTVShow]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBTVShow: Codable {
    let id: Int
    let name: String
    let originalName: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String
    let voteAverage: Double
    let voteCount: Int
    let genreIds: [Int]

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case originalName = "original_name"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case genreIds = "genre_ids"
    }

    func toMovie(providers: [StreamingProvider] = []) -> Movie {
        Movie(
            id: id,
            title: name,
            originalTitle: originalName,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: firstAirDate,
            voteAverage: voteAverage,
            voteCount: voteCount,
            genreIds: genreIds,
            availableOn: providers,
            runtime: nil,
            mediaType: .series
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
