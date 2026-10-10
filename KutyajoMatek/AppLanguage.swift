import Foundation
import ObjectiveC

/// In-app language choice. `system` follows the device language.
enum AppLanguagePreference: String, CaseIterable, Codable, Identifiable, Sendable {
    case system
    case hungarian
    case english

    var id: String { rawValue }

    /// BCP-47 language code used for string lookup (`hu` / `en`).
    var localizationLanguageCode: String {
        switch self {
        case .hungarian:
            return "hu"
        case .english:
            return "en"
        case .system:
            return Self.systemLanguageCode
        }
    }

    /// Locale used for SwiftUI and `String(localized:)`.
    var resolvedLocale: Locale {
        Locale(identifier: localizationLanguageCode)
    }

    /// Bundle containing the compiled `.lproj` strings for this preference.
    var localizationBundle: Bundle {
        LanguageSettings.bundle(forLanguageCode: localizationLanguageCode) ?? .main
    }

    /// Prefer Hungarian or English from system settings; otherwise fall back to English.
    private static var systemLanguageCode: String {
        for language in Locale.preferredLanguages {
            if language.hasPrefix("hu") { return "hu" }
            if language.hasPrefix("en") { return "en" }
        }
        if let code = Locale.autoupdatingCurrent.language.languageCode?.identifier {
            if code.hasPrefix("hu") { return "hu" }
            if code.hasPrefix("en") { return "en" }
        }
        return "en"
    }

    var pickerTitle: String {
        switch self {
        case .system:
            return L10n.text("Rendszer nyelve")
        case .hungarian:
            return L10n.text("Magyar")
        case .english:
            return L10n.text("English")
        }
    }

    /// Always-visible label so options stay clear while switching languages.
    var stableLabel: String {
        switch self {
        case .system: return "System / Rendszer"
        case .hungarian: return "Magyar"
        case .english: return "English"
        }
    }
}

/// Shared locale + language used by `L10n` and SwiftUI string lookup.
enum LanguageSettings {
    private static let lock = NSLock()
    private static var _languageCode = "hu"
    private static var _locale = Locale(identifier: "hu")
    /// Concrete `*.lproj` bundle when available (never the swizzled `Bundle.main`).
    private static var _lprojBundle: Bundle?

    static var languageCode: String {
        lock.lock()
        defer { lock.unlock() }
        return _languageCode
    }

    static var locale: Locale {
        lock.lock()
        defer { lock.unlock() }
        return _locale
    }

    /// Bundle used for explicit `String(localized:bundle:)` lookups.
    static var bundle: Bundle {
        lock.lock()
        defer { lock.unlock() }
        return _lprojBundle ?? bundle(forLanguageCode: _languageCode) ?? .main
    }

    static func apply(_ preference: AppLanguagePreference) {
        let code = preference.localizationLanguageCode
        let locale = preference.resolvedLocale
        let lproj = bundle(forLanguageCode: code)

        lock.lock()
        _languageCode = code
        _locale = locale
        _lprojBundle = lproj
        lock.unlock()

        LanguageAwareBundle.installIfNeeded()
    }

    static func bundle(forLanguageCode code: String) -> Bundle? {
        guard
            let path = Bundle.main.path(forResource: code, ofType: "lproj"),
            let languageBundle = Bundle(path: path)
        else {
            return nil
        }
        return languageBundle
    }
}

/// Redirects `Bundle.main` string lookup to the in-app language `.lproj`.
///
/// Needed because SwiftUI `Text` / `Label` / `Button` titles resolve through `Bundle.main`,
/// and `String(localized:locale:)` alone often still follows the device language.
private final class LanguageAwareBundle: Bundle, @unchecked Sendable {
    private static var didInstall = false

    static func installIfNeeded() {
        guard !didInstall else { return }
        object_setClass(Bundle.main, LanguageAwareBundle.self)
        didInstall = true
    }

    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let languageBundle = LanguageSettings.bundle(forLanguageCode: LanguageSettings.languageCode) {
            return languageBundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}
