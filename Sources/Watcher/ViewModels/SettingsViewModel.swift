import Foundation
import SwiftUI

final class SettingsViewModel: ObservableObject {
    private let apiKeyStorageKey = "tmdb_api_key"

    @Published var apiKey: String = UserDefaults.standard.string(forKey: "tmdb_api_key") ?? "" {
        didSet {
            let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                UserDefaults.standard.removeObject(forKey: apiKeyStorageKey)
            } else {
                UserDefaults.standard.set(trimmed, forKey: apiKeyStorageKey)
            }
            apiKeyState = .unchecked
        }
    }

    @AppStorage("color_scheme") var colorSchemeRaw: String = "system"

    @Published var apiKeyState: APIKeyState = .unchecked
    @Published var isValidating = false

    var colorSchemePreference: ColorSchemePreference {
        get { ColorSchemePreference(rawValue: colorSchemeRaw) ?? .system }
        set { colorSchemeRaw = newValue.rawValue }
    }

    var colorScheme: ColorScheme? {
        switch colorSchemePreference {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return nil
        }
    }

    func validateAPIKey() async {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            apiKeyState = .invalid(String(localized: "settings.api_key.empty"))
            return
        }
        isValidating = true
        let valid = await TMDBService.shared.validateAPIKey(apiKey)
        isValidating = false
        apiKeyState = valid
            ? .valid
            : .invalid(String(localized: "settings.api_key.invalid"))
    }
}

// MARK: - API Key State

enum APIKeyState: Equatable {
    case unchecked
    case valid
    case invalid(String)

    var icon: String {
        switch self {
        case .unchecked: return "questionmark.circle"
        case .valid:     return "checkmark.circle.fill"
        case .invalid:   return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .unchecked: return .secondary
        case .valid:     return .green
        case .invalid:   return .red
        }
    }

    var message: String? {
        switch self {
        case .invalid(let msg): return msg
        default: return nil
        }
    }
}

// MARK: - Color scheme preference

enum ColorSchemePreference: String, CaseIterable {
    case system, light, dark

    var localizedName: String {
        switch self {
        case .system: return String(localized: "settings.theme.system")
        case .light:  return String(localized: "settings.theme.light")
        case .dark:   return String(localized: "settings.theme.dark")
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}
