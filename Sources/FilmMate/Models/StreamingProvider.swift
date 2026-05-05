import Foundation
import SwiftUI

enum StreamingProvider: Int, CaseIterable, Identifiable, Codable {
    case netflix = 8
    case amazonPrime = 9
    case disneyPlus = 337
    case hboMax = 1899
    case paramountPlus = 531
    case crunchyroll = 283
    case appleTVPlus = 350
    case sky = 210
    case joyn = 304
    case rtlPlus = 298
    case magentaTV = 178
    case wow = 30
    case plutoTV = 300
    case rakutenTV = 35
    case ard = 326
    case zdf = 232
    case arte = 239
    case netzkino = 28
    case maxdome = 20

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .netflix:       return "Netflix"
        case .amazonPrime:   return "Amazon Prime"
        case .disneyPlus:    return "Disney+"
        case .hboMax:        return "HBO Max"
        case .paramountPlus: return "Paramount+"
        case .crunchyroll:   return "Crunchyroll"
        case .appleTVPlus:   return "Apple TV+"
        case .sky:           return "Sky"
        case .joyn:          return "Joyn"
        case .rtlPlus:       return "RTL+"
        case .magentaTV:     return "MagentaTV"
        case .wow:           return "WOW"
        case .plutoTV:       return "Pluto TV"
        case .rakutenTV:     return "Rakuten TV"
        case .ard:           return "ARD"
        case .zdf:           return "ZDF"
        case .arte:          return "arte"
        case .netzkino:      return "Netzkino"
        case .maxdome:       return "Maxdome"
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
        case .appleTVPlus:   return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .sky:           return Color(red: 0.0, green: 0.5, blue: 0.8)
        case .joyn:          return Color(red: 0.0, green: 0.7, blue: 0.9)
        case .rtlPlus:       return Color(red: 0.85, green: 0.15, blue: 0.15)
        case .magentaTV:     return Color(red: 0.85, green: 0.0, blue: 0.55)
        case .wow:           return Color(red: 0.5, green: 0.0, blue: 0.8)
        case .plutoTV:       return Color(red: 0.9, green: 0.3, blue: 0.0)
        case .rakutenTV:     return Color(red: 0.8, green: 0.0, blue: 0.2)
        case .ard:           return Color(red: 0.1, green: 0.3, blue: 0.6)
        case .zdf:           return Color(red: 0.0, green: 0.4, blue: 0.5)
        case .arte:          return Color(red: 0.8, green: 0.45, blue: 0.0)
        case .netzkino:      return Color(red: 0.7, green: 0.0, blue: 0.1)
        case .maxdome:       return Color(red: 0.15, green: 0.2, blue: 0.6)
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
        case .appleTVPlus:   return "applelogo"
        case .sky:           return "s.circle.fill"
        case .joyn:          return "j.circle.fill"
        case .rtlPlus:       return "r.circle.fill"
        case .magentaTV:     return "m.circle.fill"
        case .wow:           return "w.circle.fill"
        case .plutoTV:       return "sun.max.circle.fill"
        case .rakutenTV:     return "r.circle.fill"
        case .ard:           return "a.circle.fill"
        case .zdf:           return "z.circle.fill"
        case .arte:          return "tv.circle.fill"
        case .netzkino:      return "film.circle.fill"
        case .maxdome:       return "m.circle.fill"
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
        case .appleTVPlus:   return "A"
        case .sky:           return "S"
        case .joyn:          return "J"
        case .rtlPlus:       return "R"
        case .magentaTV:     return "M"
        case .wow:           return "W"
        case .plutoTV:       return "P"
        case .rakutenTV:     return "R"
        case .ard:           return "A"
        case .zdf:           return "Z"
        case .arte:          return "a"
        case .netzkino:      return "N"
        case .maxdome:       return "M"
        }
    }

    var isSeriesOnly: Bool {
        self == .crunchyroll
    }
}
