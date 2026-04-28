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
