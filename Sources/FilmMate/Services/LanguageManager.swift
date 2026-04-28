import Foundation
import ObjectiveC

// Swizzles Bundle.main so String(localized:) picks up the chosen language
// at runtime — no restart needed, no changes to existing view code.

private var associatedBundleKey: UInt8 = 0

final class LanguageManager {
    static func apply(_ languageCode: String) {
        // languageCode is e.g. "de-DE" or "en-US"; we need just "de" / "en"
        let lang = String(languageCode.prefix(2))

        guard let path = Bundle.main.path(forResource: lang, ofType: "lproj") else { return }

        // Store the path so PrivateBundle can load it
        objc_setAssociatedObject(
            Bundle.main, &associatedBundleKey,
            path, .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )

        // Swap the class of Bundle.main to our subclass (one-time, idempotent)
        object_setClass(Bundle.main, PrivateBundle.self)
    }
}

// Subclass that redirects localizedString lookups to the stored lproj bundle
private final class PrivateBundle: Bundle, @unchecked Sendable {
    override func localizedString(
        forKey key: String,
        value: String?,
        table tableName: String?
    ) -> String {
        guard
            let path   = objc_getAssociatedObject(self, &associatedBundleKey) as? String,
            let bundle = Bundle(path: path)
        else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}
