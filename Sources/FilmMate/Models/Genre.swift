import Foundation
import SwiftUI

enum Genre: Int, CaseIterable, Identifiable, Codable {
    case action = 28
    case adventure = 12
    case animation = 16
    case comedy = 35
    case crime = 80
    case documentary = 99
    case drama = 18
    case family = 10751
    case fantasy = 14
    case horror = 27
    case romance = 10749
    case scienceFiction = 878
    case thriller = 53
    case mystery = 9648
    case actionAdventure = 10759
    case sciFiFantasy = 10765

    var id: Int { rawValue }

    var localizedName: String {
        switch self {
        case .action:        return String(localized: "genre.action")
        case .adventure:     return String(localized: "genre.adventure")
        case .animation:     return String(localized: "genre.animation")
        case .comedy:        return String(localized: "genre.comedy")
        case .crime:         return String(localized: "genre.crime")
        case .documentary:   return String(localized: "genre.documentary")
        case .drama:         return String(localized: "genre.drama")
        case .family:        return String(localized: "genre.family")
        case .fantasy:       return String(localized: "genre.fantasy")
        case .horror:        return String(localized: "genre.horror")
        case .romance:       return String(localized: "genre.romance")
        case .scienceFiction: return String(localized: "genre.scifi")
        case .thriller:       return String(localized: "genre.thriller")
        case .mystery:        return String(localized: "genre.mystery")
        case .actionAdventure: return String(localized: "genre.action_adventure")
        case .sciFiFantasy:   return String(localized: "genre.scifi_fantasy")
        }
    }

    var emoji: String {
        switch self {
        case .action:        return "💥"
        case .adventure:     return "🗺️"
        case .animation:     return "🎨"
        case .comedy:        return "😂"
        case .crime:         return "🔫"
        case .documentary:   return "🎞️"
        case .drama:         return "🎭"
        case .family:        return "👨‍👩‍👧‍👦"
        case .fantasy:       return "🧙"
        case .horror:        return "👻"
        case .romance:       return "❤️"
        case .scienceFiction: return "🚀"
        case .thriller:      return "😱"
        case .mystery:       return "🔍"
        case .actionAdventure: return "⚡"
        case .sciFiFantasy:  return "🌌"
        }
    }

    var color: Color {
        switch self {
        case .action:         return Color(red: 0.92, green: 0.22, blue: 0.22) // red
        case .adventure:      return Color(red: 0.20, green: 0.63, blue: 0.29) // green
        case .animation:      return Color(red: 0.98, green: 0.60, blue: 0.05) // amber
        case .comedy:         return Color(red: 0.97, green: 0.76, blue: 0.05) // yellow
        case .crime:          return Color(red: 0.35, green: 0.35, blue: 0.40) // slate
        case .documentary:    return Color(red: 0.47, green: 0.53, blue: 0.60) // steel
        case .drama:          return Color(red: 0.56, green: 0.27, blue: 0.68) // purple
        case .family:         return Color(red: 0.07, green: 0.62, blue: 0.86) // sky
        case .fantasy:        return Color(red: 0.40, green: 0.20, blue: 0.80) // indigo
        case .horror:         return Color(red: 0.15, green: 0.15, blue: 0.15) // near-black
        case .romance:        return Color(red: 0.95, green: 0.30, blue: 0.55) // pink
        case .scienceFiction: return Color(red: 0.05, green: 0.55, blue: 0.95) // blue
        case .thriller:       return Color(red: 0.80, green: 0.40, blue: 0.10) // burnt orange
        case .mystery:        return Color(red: 0.30, green: 0.40, blue: 0.55) // slate blue
        case .actionAdventure: return Color(red: 0.85, green: 0.30, blue: 0.15) // deep orange
        case .sciFiFantasy:   return Color(red: 0.20, green: 0.45, blue: 0.80) // deep blue
        }
    }

    static func from(tmdbIds: [Int]) -> [Genre] {
        tmdbIds.compactMap { Genre(rawValue: $0) }
    }
}
