import Foundation

/// In-app language choice. `system` follows the device language.
enum AppLanguagePreference: String, CaseIterable, Codable, Identifiable, Sendable {
    case system
    case hungarian
    case english

    var id: String { rawValue }

    /// Locale used for SwiftUI and `String(localized:)`.
    var resolvedLocale: Locale {
        switch self {
        case .system:
            return Self.systemResolvedLocale
        case .hungarian:
            return Locale(identifier: "hu")
        case .english:
            return Locale(identifier: "en")
        }
    }

    /// Prefer Hungarian or English from system settings; otherwise use the system locale.
    private static var systemResolvedLocale: Locale {
        for language in Locale.preferredLanguages {
            if language.hasPrefix("hu") { return Locale(identifier: "hu") }
            if language.hasPrefix("en") { return Locale(identifier: "en") }
        }
        return Locale.autoupdatingCurrent
    }

    var pickerTitle: String {
        switch self {
        case .system:
            return String(localized: "Rendszer nyelve", locale: LanguageSettings.locale)
        case .hungarian:
            return String(localized: "Magyar", locale: LanguageSettings.locale)
        case .english:
            return String(localized: "English", locale: LanguageSettings.locale)
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

/// Shared locale used by `L10n` helpers outside the SwiftUI environment.
enum LanguageSettings {
    private static let lock = NSLock()
    private static var _locale: Locale = .autoupdatingCurrent

    static var locale: Locale {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _locale
        }
        set {
            lock.lock()
            _locale = newValue
            lock.unlock()
        }
    }
}
