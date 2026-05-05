import Foundation
import SwiftUI

enum StreamingProvider: Int, CaseIterable, Identifiable, Codable {
    case netflix = 8
    case amazonPrime = 9
    case disneyPlus = 337
    case hboMax = 1899
    case paramountPlus = 531
    case crunchyroll = 283

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .netflix:       return "Netflix"
        case .amazonPrime:   return "Amazon Prime"
        case .disneyPlus:    return "Disney+"
        case .hboMax:        return "HBO Max"
        case .paramountPlus: return "Paramount+"
        case .crunchyroll:   return "Crunchyroll"
        }
    }

    var color: Color {
        switch self {
        case .netflix:       return Color(red: 0.9, green: 0.0, blue: 0.0)
        case .amazonPrime:   return Color(red: 0.0, green: 0.47, blue: 0.78)
        case .disneyPlus:    return Color(red: 0.07, green: 0.13, blue: 0.53)
        case .hboMax:        return Color(red: 0.36, green: 0.06, blue: 0.69)
        case .paramountPlus: return Color(red: 0.0, green: 0.44, blue: 0.82)
        case .crunchyroll:   return Color(red: 0.98, green: 0.42, blue: 0.0)
        }
    }

    var iconName: String {
        switch self {
        case .netflix:       return "n.circle.fill"
        case .amazonPrime:   return "play.circle.fill"
        case .disneyPlus:    return "star.circle.fill"
        case .hboMax:        return "h.circle.fill"
        case .paramountPlus: return "p.circle.fill"
        case .crunchyroll:   return "c.circle.fill"
        }
    }

    var initial: String {
        switch self {
        case .netflix:       return "N"
        case .amazonPrime:   return "A"
        case .disneyPlus:    return "D"
        case .hboMax:        return "H"
        case .paramountPlus: return "P"
        case .crunchyroll:   return "C"
        }
    }
}
