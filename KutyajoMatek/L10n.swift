import Foundation

/// Central helpers for interpolated / non-literal localized strings.
/// Plain `Text("…")` views follow the SwiftUI `locale` environment.
enum L10n {
    private static var locale: Locale { LanguageSettings.locale }

    private static func localized(_ value: String.LocalizationValue) -> String {
        String(localized: value, locale: locale)
    }

    static func hiName(_ name: String) -> String {
        localized("Szia, \(name)!")
    }

    static func dogsCollected(_ count: Int) -> String {
        localized("\(count) megszerzett kutyus")
    }

    static func dogsOwnedProgress(owned: Int, total: Int) -> String {
        localized("\(owned) / \(total) kutyus már a tiéd")
    }

    static func dogsAndRounds(dogs: Int, rounds: Int) -> String {
        localized("\(dogs) kutyus · \(rounds) kör")
    }

    static func profileAvatarAccessibility(_ name: String) -> String {
        localized("\(name) profilképe")
    }

    static func opensGameAccessibility(_ name: String) -> String {
        localized("Megnyitja \(name) játékát")
    }

    static func dogPortraitAccessibility(_ name: String) -> String {
        localized("\(name) kutyus")
    }

    static func almostCorrect(answer: Int) -> String {
        localized("Majdnem! A helyes válasz: \(answer)")
    }

    static func correctAnswers(_ correct: Int, total: Int) -> String {
        localized("\(correct) / \(total) helyes válasz")
    }

    static func meetDog(_ name: String) -> String {
        localized("Ő \(name)!")
    }

    static func levelUnlocked(_ label: String) -> String {
        localized("Szint nyílt! \(label)")
    }

    static func dogSaidGoodbye(_ name: String) -> String {
        localized("Most \(name) elbúcsúzott")
    }

    static func practiceUnlocked(_ title: String) -> String {
        localized("Fantasztikus munka! Most már gyakorolhatod: \(title).")
    }

    static func modeSubtitleCurrent(_ subtitle: String, label: String) -> String {
        localized("\(subtitle) · Most: \(label)")
    }

    static func multiplicationTableTitle(_ table: Int) -> String {
        localized("Szorzás \(table)-vel")
    }

    static func divisionTableTitle(_ table: Int) -> String {
        localized("Osztás \(table)-vel")
    }

    static func remainingMasteryRounds(_ remaining: Int) -> String {
        localized("Még \(remaining) ügyes kör a következő szinthez")
    }

    static func levelLockedAccessibility(_ title: String) -> String {
        localized("\(title), zárva")
    }

    static func resetProgressTitle(_ name: String) -> String {
        localized("\(name) haladásának törlése?")
    }

    static func deleteProfileTitle(_ name: String) -> String {
        localized("\(name) profiljának törlése?")
    }

    static func resetProgressMessage(_ name: String) -> String {
        localized("\(name) összes kutyusa, eredménye és szintje törlődik. A név és a profilkép megmarad.")
    }

    static func deleteProfileMessage(_ name: String) -> String {
        localized("\(name) profilja, kutyusai, eredményei és a mentett profilkép véglegesen törlődnek. Ez a többi profilt nem érinti.")
    }

    static func spokenTimes() -> String {
        String(localized: "szorozva", locale: locale)
    }

    static func spokenDivided() -> String {
        String(localized: "osztva", locale: locale)
    }

    static func text(_ key: String.LocalizationValue) -> String {
        localized(key)
    }
}
