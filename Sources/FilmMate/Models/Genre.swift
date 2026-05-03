import Foundation
import SwiftUI

enum Genre: Int, CaseIterable, Identifiable, Codable {
    case action = 28
    case animation = 16
    case comedy = 35
    case crime = 80
    case drama = 18
    case fantasy = 14
    case horror = 27
    case romance = 10749
    case scienceFiction = 878
    case thriller = 53

    var id: Int { rawValue }

    var localizedName: String {
        switch self {
        case .action:         return String(localized: "genre.action")
        case .animation:      return String(localized: "genre.animation")
        case .comedy:         return String(localized: "genre.comedy")
        case .crime:          return String(localized: "genre.crime")
        case .drama:          return String(localized: "genre.drama")
        case .fantasy:        return String(localized: "genre.fantasy")
        case .horror:         return String(localized: "genre.horror")
        case .romance:        return String(localized: "genre.romance")
        case .scienceFiction: return String(localized: "genre.scifi")
        case .thriller:       return String(localized: "genre.thriller")
        }
    }

    var emoji: String {
        switch self {
        case .action:         return "💥"
        case .animation:      return "🎨"
        case .comedy:         return "😂"
        case .crime:          return "🔫"
        case .drama:          return "🎭"
        case .fantasy:        return "🧙"
        case .horror:         return "👻"
        case .romance:        return "❤️"
        case .scienceFiction: return "🚀"
        case .thriller:       return "😱"
        }
    }

    var color: Color {
        switch self {
        case .action:         return Color(red: 0.92, green: 0.22, blue: 0.22) // red
        case .animation:      return Color(red: 0.98, green: 0.60, blue: 0.05) // amber
        case .comedy:         return Color(red: 0.97, green: 0.76, blue: 0.05) // yellow
        case .crime:          return Color(red: 0.35, green: 0.35, blue: 0.40) // slate
        case .drama:          return Color(red: 0.56, green: 0.27, blue: 0.68) // purple
        case .fantasy:        return Color(red: 0.40, green: 0.20, blue: 0.80) // indigo
        case .horror:         return Color(red: 0.65, green: 0.10, blue: 0.10) // dark red
        case .romance:        return Color(red: 0.95, green: 0.30, blue: 0.55) // pink
        case .scienceFiction: return Color(red: 0.05, green: 0.55, blue: 0.95) // blue
        case .thriller:       return Color(red: 0.80, green: 0.40, blue: 0.10) // burnt orange
        }
    }

    static func from(tmdbIds: [Int]) -> [Genre] {
        tmdbIds.compactMap { Genre(rawValue: $0) }
    }
}
