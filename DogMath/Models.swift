import Foundation
import SwiftUI

struct PlayerProfile: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    let symbol: String

    static let laura = PlayerProfile(id: "laura", name: "Laura", symbol: "sparkles")
    static let izabella = PlayerProfile(id: "isabella", name: "Izabella", symbol: "heart.fill")
    static let all: [PlayerProfile] = [.izabella, .laura]

    var tint: Color {
        id == "laura" ? Color(red: 0.60, green: 0.42, blue: 0.86) : Color(red: 0.95, green: 0.39, blue: 0.58)
    }
}

struct PlayerProgress: Codable, Equatable {
    var collectedDogIDs: [Int] = []
    var failedRounds: Int = 0
    var totalCorrectAnswers: Int = 0
    var completedRounds: Int = 0
}

enum GameMode: String, CaseIterable, Identifiable, Codable, Sendable {
    case multiplication
    case division
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .multiplication: "Szorzás"
        case .division: "Osztás"
        case .mixed: "Vegyes"
        }
    }

    var subtitle: String {
        switch self {
        case .multiplication: "Öt szorzás a százas számkörben"
        case .division: "Öt maradék nélküli osztás"
        case .mixed: "Szorzás és osztás felváltva"
        }
    }

    var symbol: String {
        switch self {
        case .multiplication: "multiply"
        case .division: "divide"
        case .mixed: "shuffle"
        }
    }
}

enum MathOperation: Equatable, Sendable {
    case multiplication
    case division
}

struct MathQuestion: Identifiable, Equatable, Sendable {
    let id = UUID()
    let left: Int
    let right: Int
    let operation: MathOperation
    let answer: Int
    let choices: [Int]

    var prompt: String {
        "\(left) \(operation == .multiplication ? "×" : "÷") \(right) = ?"
    }
}

enum QuestionFactory {
    static func makeRound(mode: GameMode) -> [MathQuestion] {
        (0..<5).map { index in
            let operation: MathOperation = switch mode {
            case .multiplication: .multiplication
            case .division: .division
            case .mixed: index.isMultiple(of: 2) ? .multiplication : .division
            }
            return makeQuestion(operation: operation)
        }
    }

    static func makeQuestion(operation: MathOperation) -> MathQuestion {
        let firstFactor = Int.random(in: 1...10)
        let secondFactor = Int.random(in: 1...10)

        let left: Int
        let right: Int
        let answer: Int

        switch operation {
        case .multiplication:
            left = firstFactor
            right = secondFactor
            answer = firstFactor * secondFactor
        case .division:
            left = firstFactor * secondFactor
            right = secondFactor
            answer = firstFactor
        }

        return MathQuestion(
            left: left,
            right: right,
            operation: operation,
            answer: answer,
            choices: makeChoices(for: answer)
        )
    }

    private static func makeChoices(for answer: Int) -> [Int] {
        var choices: Set<Int> = [answer]
        let usefulOffsets = [-10, -5, -3, -2, -1, 1, 2, 3, 5, 10].shuffled()

        for offset in usefulOffsets where choices.count < 3 {
            let candidate = answer + offset
            if (0...100).contains(candidate) {
                choices.insert(candidate)
            }
        }

        while choices.count < 3 {
            choices.insert(Int.random(in: 0...100))
        }

        return choices.shuffled()
    }
}

enum DogCatalog {
    static let count = 40
    static let names = [
        "Masni", "Hópihe", "Zsömle", "Pötty", "Bodza",
        "Málna", "Lili", "Füge", "Morzsi", "Csillag",
        "Mézi", "Keksz", "Panka", "Zizi", "Bella",
        "Mimi", "Dió", "Pihe", "Szofi", "Bogyó",
        "Luna", "Cukor", "Süni", "Nara", "Puszedli",
        "Mokka", "Nelli", "Kókusz", "Manci", "Picur",
        "Szirom", "Barack", "Felhő", "Menta", "Gombóc",
        "Rozé", "Pamacs", "Csoki", "Tulipán", "Mazsi"
    ]

    static func name(for id: Int) -> String {
        names.indices.contains(id) ? names[id] : "Kutyus"
    }

    static func imageName(for id: Int) -> String {
        String(format: "dog_%02d", id + 1)
    }
}
