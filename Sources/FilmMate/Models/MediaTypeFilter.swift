import Foundation

enum MediaTypeFilter: String, CaseIterable, Identifiable {
    case all, movies, series

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:    return String(localized: "content.all")
        case .movies: return String(localized: "content.movies")
        case .series: return String(localized: "content.series")
        }
    }
}
