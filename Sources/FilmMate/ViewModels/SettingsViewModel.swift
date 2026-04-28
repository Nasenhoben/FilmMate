import Foundation
import SwiftUI
import AppKit

final class SettingsViewModel: ObservableObject {
    // API key lives in Keychain, not UserDefaults
    @Published var apiKey: String = KeychainService.shared.retrieve() ?? "" {
        didSet {
            KeychainService.shared.save(apiKey)
            apiKeyState = .unchecked
        }
    }

    @AppStorage("app_language") var language: String = "de-DE"
    @AppStorage("color_scheme") var colorSchemeRaw: String = "system"

    @Published var isRestarting = false
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

    var availableLanguages: [(code: String, name: String)] {
        [("de-DE", "Deutsch"), ("en-US", "English")]
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

    func setLanguage(_ code: String) {
        guard code != language else { return }
        language = code
        UserDefaults.standard.set([String(code.prefix(2))], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        isRestarting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            Self.restartApp()
        }
    }

    static func restartApp() {
        let bundlePath = Bundle.main.bundlePath
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "sleep 0.8 && open \"\(bundlePath)\""]
        task.launch()
        NSApp.terminate(nil)
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
