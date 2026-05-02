import Foundation

struct TMDBMovieDetailResponse: Codable {
    let id: Int
    let runtime: Int?
    let credits: Credits?

    struct Credits: Codable {
        let cast: [CastMember]
        let crew: [CrewMember]
    }

    struct CastMember: Codable, Identifiable {
        let id: Int
        let name: String
        let character: String
        let profilePath: String?

        enum CodingKeys: String, CodingKey {
            case id, name, character
            case profilePath = "profile_path"
        }

        var profileURL: URL? {
            guard let path = profilePath else { return nil }
            return URL(string: "https://image.tmdb.org/t/p/w185\(path)")
        }
    }

    struct CrewMember: Codable {
        let name: String
        let job: String
    }

    var director: String? {
        credits?.crew.first { $0.job == "Director" }?.name
    }

    var topCast: [CastMember] {
        Array(credits?.cast.prefix(5) ?? [])
    }
}

struct TMDBSeriesDetailResponse: Codable {
    let id: Int
    let numberOfSeasons: Int?
    let numberOfEpisodes: Int?
    let episodeRunTime: [Int]?
    let createdBy: [Creator]?
    let credits: TMDBMovieDetailResponse.Credits?

    enum CodingKeys: String, CodingKey {
        case id
        case numberOfSeasons = "number_of_seasons"
        case numberOfEpisodes = "number_of_episodes"
        case episodeRunTime = "episode_run_time"
        case createdBy = "created_by"
        case credits
    }

    struct Creator: Codable, Identifiable {
        let id: Int
        let name: String
    }

    var averageEpisodeRuntime: Int? {
        guard let runtimes = episodeRunTime, !runtimes.isEmpty else { return nil }
        return runtimes.reduce(0, +) / runtimes.count
    }

    var creatorNames: String? {
        guard let creators = createdBy, !creators.isEmpty else { return nil }
        return creators.map(\.name).joined(separator: ", ")
    }

    var topCast: [TMDBMovieDetailResponse.CastMember] {
        Array(credits?.cast.prefix(5) ?? [])
    }
}
