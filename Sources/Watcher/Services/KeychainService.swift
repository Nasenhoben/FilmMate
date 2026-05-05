import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()
    private let service = "com.watcher.Watcher"
    private let legacyService = "com.filmmate.FilmMate"
    private let account = "tmdb_api_key"
    private let legacyUserDefaultsKey = "tmdb_api_key"

    private init() {
        migrateFromUserDefaults()
    }

    func save(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            delete()
            return
        }

        let data = Data(trimmed.utf8)
        let query = baseQuery(service: service)
        let attributes: [CFString: Any] = [kSecValueData: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func retrieve() -> String? {
        var query = baseQuery(service: service)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty
        else { return nil }

        return value
    }

    func delete() {
        SecItemDelete(baseQuery(service: service) as CFDictionary)
        SecItemDelete(baseQuery(service: legacyService) as CFDictionary)
        UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
    }

    private func baseQuery(service: String) -> [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
    }

    private func migrateFromUserDefaults() {
        if retrieve() == nil, let legacyKeychainValue = retrieve(service: legacyService) {
            save(legacyKeychainValue)
        }

        guard retrieve() == nil,
              let legacyValue = UserDefaults.standard.string(forKey: legacyUserDefaultsKey),
              !legacyValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }

        save(legacyValue)
        UserDefaults.standard.removeObject(forKey: legacyUserDefaultsKey)
    }

    private func retrieve(service: String) -> String? {
        var query = baseQuery(service: service)
        query[kSecReturnData] = true
        query[kSecMatchLimit] = kSecMatchLimitOne

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty
        else { return nil }

        return value
    }
}
