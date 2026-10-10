import Foundation

/// Central helpers for interpolated / non-literal localized strings.
/// Plain `Text("…")` views use the Hungarian source strings as catalog keys.
enum L10n {
    static func hiName(_ name: String) -> String {
        String(localized: "Szia, \(name)!")
    }

    static func dogsCollected(_ count: Int) -> String {
        String(localized: "\(count) megszerzett kutyus")
    }

    static func dogsOwnedProgress(owned: Int, total: Int) -> String {
        String(localized: "\(owned) / \(total) kutyus már a tiéd")
    }

    static func dogsAndRounds(dogs: Int, rounds: Int) -> String {
        String(localized: "\(dogs) kutyus · \(rounds) kör")
    }

    static func profileAvatarAccessibility(_ name: String) -> String {
        String(localized: "\(name) profilképe")
    }

    static func opensGameAccessibility(_ name: String) -> String {
        String(localized: "Megnyitja \(name) játékát")
    }

    static func dogPortraitAccessibility(_ name: String) -> String {
        String(localized: "\(name) kutyus")
    }

    static func almostCorrect(answer: Int) -> String {
        String(localized: "Majdnem! A helyes válasz: \(answer)")
    }

    static func correctAnswers(_ correct: Int, total: Int) -> String {
        String(localized: "\(correct) / \(total) helyes válasz")
    }

    static func meetDog(_ name: String) -> String {
        String(localized: "Ő \(name)!")
    }

    static func levelUnlocked(_ label: String) -> String {
        String(localized: "Szint nyílt! \(label)")
    }

    static func dogSaidGoodbye(_ name: String) -> String {
        String(localized: "Most \(name) elbúcsúzott")
    }

    static func practiceUnlocked(_ title: String) -> String {
        String(localized: "Fantasztikus munka! Most már gyakorolhatod: \(title).")
    }

    static func modeSubtitleCurrent(_ subtitle: String, label: String) -> String {
        String(localized: "\(subtitle) · Most: \(label)")
    }

    static func multiplicationTableTitle(_ table: Int) -> String {
        String(localized: "Szorzás \(table)-vel")
    }

    static func divisionTableTitle(_ table: Int) -> String {
        String(localized: "Osztás \(table)-vel")
    }

    static func remainingMasteryRounds(_ remaining: Int) -> String {
        String(localized: "Még \(remaining) ügyes kör a következő szinthez")
    }

    static func levelLockedAccessibility(_ title: String) -> String {
        String(localized: "\(title), zárva")
    }

    static func resetProgressTitle(_ name: String) -> String {
        String(localized: "\(name) haladásának törlése?")
    }

    static func deleteProfileTitle(_ name: String) -> String {
        String(localized: "\(name) profiljának törlése?")
    }

    static func resetProgressMessage(_ name: String) -> String {
        String(localized: "\(name) összes kutyusa, eredménye és szintje törlődik. A név és a profilkép megmarad.")
    }

    static func deleteProfileMessage(_ name: String) -> String {
        String(localized: "\(name) profilja, kutyusai, eredményei és a mentett profilkép véglegesen törlődnek. Ez a többi profilt nem érinti.")
    }

    static func spokenTimes() -> String {
        String(localized: "szorozva")
    }

    static func spokenDivided() -> String {
        String(localized: "osztva")
    }
}
