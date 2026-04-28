import Foundation

enum RuntimeFilter: String, CaseIterable, Identifiable {
    case all
    case short
    case medium
    case long

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:    return String(localized: "runtime.all")
        case .short:  return String(localized: "runtime.short")
        case .medium: return String(localized: "runtime.medium")
        case .long:   return String(localized: "runtime.long")
        }
    }

    func matches(_ runtime: Int?) -> Bool {
        guard let runtime else { return true } // Laufzeit unbekannt → immer zeigen
        switch self {
        case .all:    return true
        case .short:  return runtime < 90
        case .medium: return runtime >= 90 && runtime <= 150
        case .long:   return runtime > 150
        }
    }
}
