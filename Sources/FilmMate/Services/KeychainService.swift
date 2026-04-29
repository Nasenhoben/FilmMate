import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private let key = "tmdb_api_key"

    private init() {
        migrateFromKeychain()
    }

    func save(_ value: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    func retrieve() -> String? {
        UserDefaults.standard.string(forKey: key)
    }

    func delete() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    // Move existing Keychain entry to UserDefaults once, then delete from Keychain
    private func migrateFromKeychain() {
        guard UserDefaults.standard.string(forKey: key) == nil else { return }

        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: "com.filmmate.FilmMate",
            kSecAttrAccount: "tmdb_api_key",
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        if SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8),
           !value.isEmpty {
            UserDefaults.standard.set(value, forKey: key)
        }

        let deleteQuery: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: "com.filmmate.FilmMate",
            kSecAttrAccount: "tmdb_api_key"
        ]
        SecItemDelete(deleteQuery as CFDictionary)
    }
}
