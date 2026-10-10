import Foundation
import SwiftUI

struct PlayerProfile: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var name: String
    var symbol: String
    var avatarFileName: String?
    var accentIndex: Int

    static let legacyLauraID = "laura"
    static let legacyIzabellaID = "isabella"

    /// Convenience profiles used by tests and legacy migration seeds.
    static let laura = PlayerProfile(
        id: legacyLauraID,
        name: "Laura",
        symbol: "sparkles",
        avatarFileName: nil,
        accentIndex: 1
    )
    static let izabella = PlayerProfile(
        id: legacyIzabellaID,
        name: "Izabella",
        symbol: "heart.fill",
        avatarFileName: nil,
        accentIndex: 0
    )

    static let defaultSymbols = ["heart.fill", "sparkles", "star.fill", "hare.fill", "leaf.fill", "teddybear.fill"]
    static let accentColors: [Color] = [
        Color(red: 0.95, green: 0.39, blue: 0.58),
        Color(red: 0.60, green: 0.42, blue: 0.86),
        Color(red: 0.44, green: 0.77, blue: 0.68),
        Color(red: 1.00, green: 0.70, blue: 0.55),
        Color(red: 0.36, green: 0.62, blue: 0.90),
        Color(red: 0.95, green: 0.55, blue: 0.35)
    ]

    static func makeNew(name: String, accentIndex: Int = 0) -> PlayerProfile {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let index = max(0, accentIndex)
        return PlayerProfile(
            id: UUID().uuidString,
            name: trimmed,
            symbol: defaultSymbols[index % defaultSymbols.count],
            avatarFileName: nil,
            accentIndex: index
        )
    }

    var tint: Color {
        Self.accentColors[accentIndex % Self.accentColors.count]
    }

    var displayInitial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.first.map { String($0).uppercased() } ?? "?"
    }
}

struct PlayerProgress: Codable, Equatable {
    var collectedDogIDs: [Int] = []
    var failedRounds: Int = 0
    var totalCorrectAnswers: Int = 0
    var completedRounds: Int = 0
    var learning: LearningProgress = LearningProgress()

    enum CodingKeys: String, CodingKey {
        case collectedDogIDs
        case failedRounds
        case totalCorrectAnswers
        case completedRounds
        case learning
    }

    init(
        collectedDogIDs: [Int] = [],
        failedRounds: Int = 0,
        totalCorrectAnswers: Int = 0,
        completedRounds: Int = 0,
        learning: LearningProgress = LearningProgress()
    ) {
        self.collectedDogIDs = collectedDogIDs
        self.failedRounds = failedRounds
        self.totalCorrectAnswers = totalCorrectAnswers
        self.completedRounds = completedRounds
        self.learning = learning
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        collectedDogIDs = try container.decodeIfPresent([Int].self, forKey: .collectedDogIDs) ?? []
        failedRounds = try container.decodeIfPresent(Int.self, forKey: .failedRounds) ?? 0
        totalCorrectAnswers = try container.decodeIfPresent(Int.self, forKey: .totalCorrectAnswers) ?? 0
        completedRounds = try container.decodeIfPresent(Int.self, forKey: .completedRounds) ?? 0
        learning = try container.decodeIfPresent(LearningProgress.self, forKey: .learning) ?? LearningProgress()
    }
}

struct LearningProgress: Codable, Equatable {
    var multiplication: OperationPathProgress = OperationPathProgress()
    var division: OperationPathProgress = OperationPathProgress()

    func path(for operation: MathOperation) -> OperationPathProgress {
        switch operation {
        case .multiplication: multiplication
        case .division: division
        }
    }

    mutating func updatePath(for operation: MathOperation, mutation: (inout OperationPathProgress) -> Void) {
        switch operation {
        case .multiplication: mutation(&multiplication)
        case .division: mutation(&division)
        }
    }
}

struct OperationPathProgress: Codable, Equatable {
    /// Highest unlocked level number in `1...LearningLevel.count`.
    var unlockedLevel: Int = 1
    /// Mastery-quality round counts per level, indexed by `levelNumber - 1`.
    var masteryWins: [Int]

    enum CodingKeys: String, CodingKey {
        case unlockedLevel
        case masteryWins
    }

    init(unlockedLevel: Int = 1, masteryWins: [Int]? = nil) {
        self.unlockedLevel = min(max(unlockedLevel, 1), LearningLevel.count)
        self.masteryWins = Self.normalizedWins(masteryWins)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        unlockedLevel = min(
            max(try container.decodeIfPresent(Int.self, forKey: .unlockedLevel) ?? 1, 1),
            LearningLevel.count
        )
        masteryWins = Self.normalizedWins(try container.decodeIfPresent([Int].self, forKey: .masteryWins))
    }

    func masteryWins(for level: LearningLevel) -> Int {
        masteryWins[level.number - 1]
    }

    func status(for level: LearningLevel) -> LevelStatus {
        if level.number > unlockedLevel {
            return .locked
        }
        if level.number < unlockedLevel || masteryWins(for: level) >= LearningRules.masteryRoundsRequired {
            return .completed
        }
        return .current
    }

    func difficultyTier(for level: LearningLevel) -> Int {
        min(3, masteryWins(for: level) + 1)
    }

    private static func normalizedWins(_ wins: [Int]?) -> [Int] {
        var values = wins ?? Array(repeating: 0, count: LearningLevel.count)
        if values.count < LearningLevel.count {
            values.append(contentsOf: Array(repeating: 0, count: LearningLevel.count - values.count))
        } else if values.count > LearningLevel.count {
            values = Array(values.prefix(LearningLevel.count))
        }
        return values.map { max(0, $0) }
    }
}

enum LevelStatus: Equatable, Sendable {
    case locked
    case current
    case completed
}

enum LearningRules {
    static let questionsPerRound = 5
    static let masteryAccuracyThreshold = 0.8
    static let masteryRoundsRequired = 2
    static let minimumCorrectForMastery = Int((Double(questionsPerRound) * masteryAccuracyThreshold).rounded(.up))

    static func isMasteryQuality(correctCount: Int) -> Bool {
        correctCount >= minimumCorrectForMastery
    }
}

struct LearningLevel: Identifiable, Hashable, Codable, Sendable {
    static let count = 9
    static let all: [LearningLevel] = (1...count).map(LearningLevel.init(number:))

    let number: Int

    var id: Int { number }
    var table: Int { number + 1 }

    init(number: Int) {
        self.number = min(max(number, 1), Self.count)
    }

    func title(for operation: MathOperation) -> String {
        switch operation {
        case .multiplication: "Szorzás \(table)-vel"
        case .division: "Osztás \(table)-vel"
        }
    }

    func shortLabel(for operation: MathOperation) -> String {
        switch operation {
        case .multiplication: "× \(table)"
        case .division: "÷ \(table)"
        }
    }
}

struct PracticeConfiguration: Hashable, Sendable {
    let mode: GameMode
    let level: LearningLevel?

    static let mixed = PracticeConfiguration(mode: .mixed, level: nil)

    static func progressive(operation: MathOperation, level: LearningLevel) -> PracticeConfiguration {
        let mode: GameMode = operation == .multiplication ? .multiplication : .division
        return PracticeConfiguration(mode: mode, level: level)
    }

    var operation: MathOperation? {
        switch mode {
        case .multiplication: .multiplication
        case .division: .division
        case .mixed: nil
        }
    }

    var navigationTitle: String {
        if let level, let operation {
            return "\(mode.title) · \(level.shortLabel(for: operation))"
        }
        return mode.title
    }
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
        case .multiplication: "Szorzótábla 2-től 10-ig, szintről szintre"
        case .division: "Osztás 2-től 10-ig, szintről szintre"
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

    var progressiveOperation: MathOperation? {
        switch self {
        case .multiplication: .multiplication
        case .division: .division
        case .mixed: nil
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

struct LearningRoundOutcome: Equatable, Sendable {
    let isMasteryQuality: Bool
    let unlockedLevel: LearningLevel?
    let masteredAllLevels: Bool
}

enum QuestionFactory {
    /// Smallest multiplication/division table used in ordered practice.
    static let firstTable = 2
    /// Largest multiplication/division table used in ordered practice.
    static let lastTable = 10

    static func makeRound(mode: GameMode) -> [MathQuestion] {
        makeRound(configuration: PracticeConfiguration(mode: mode, level: nil), difficultyTier: 1)
    }

    static func makeRound(configuration: PracticeConfiguration, difficultyTier: Int) -> [MathQuestion] {
        switch configuration.mode {
        case .mixed:
            return makeMixedRound(difficultyTier: difficultyTier)
        case .multiplication, .division:
            let operation = configuration.operation ?? .multiplication
            if let level = configuration.level {
                return makeTableRound(
                    operation: operation,
                    table: level.table,
                    difficultyTier: difficultyTier
                )
            }
            // Open practice without a level still walks tables 2 → 3 → 4… instead of random hard pairs.
            return makeAscendingTablesRound(operation: operation, difficultyTier: difficultyTier)
        }
    }

    static func makeQuestion(operation: MathOperation) -> MathQuestion {
        let firstFactor = Int.random(in: 1...10)
        let secondFactor = Int.random(in: 1...10)
        return makeQuestion(operation: operation, firstFactor: firstFactor, secondFactor: secondFactor)
    }

    static func makeTableQuestion(
        operation: MathOperation,
        table: Int,
        otherFactor: Int,
        swapOperands: Bool = false
    ) -> MathQuestion {
        switch operation {
        case .multiplication:
            let left = swapOperands ? otherFactor : table
            let right = swapOperands ? table : otherFactor
            return makeQuestion(operation: .multiplication, firstFactor: left, secondFactor: right)
        case .division:
            return makeQuestion(operation: .division, firstFactor: otherFactor, secondFactor: table)
        }
    }

    /// Mixed practice: tables rise in order (2, 3, 4…) while alternating × and ÷.
    private static func makeMixedRound(difficultyTier: Int) -> [MathQuestion] {
        let tables = ascendingTables(count: LearningRules.questionsPerRound, difficultyTier: difficultyTier)
        let otherFactors = ascendingOtherFactors(
            count: LearningRules.questionsPerRound,
            difficultyTier: difficultyTier
        )

        return zip(tables, otherFactors).enumerated().map { index, pair in
            let (table, otherFactor) = pair
            let operation: MathOperation = index.isMultiple(of: 2) ? .multiplication : .division
            return makeTableQuestion(
                operation: operation,
                table: table,
                otherFactor: otherFactor,
                swapOperands: false
            )
        }
    }

    /// Single-operation practice that steps through tables 2 → 3 → 4… in order.
    private static func makeAscendingTablesRound(
        operation: MathOperation,
        difficultyTier: Int
    ) -> [MathQuestion] {
        let tables = ascendingTables(count: LearningRules.questionsPerRound, difficultyTier: difficultyTier)
        let otherFactors = ascendingOtherFactors(
            count: LearningRules.questionsPerRound,
            difficultyTier: difficultyTier
        )

        return zip(tables, otherFactors).map { table, otherFactor in
            makeTableQuestion(
                operation: operation,
                table: table,
                otherFactor: otherFactor,
                swapOperands: false
            )
        }
    }

    /// One selected table (e.g. ×4): other factors rise in order (1, 2, 3…) so the round stays gentle.
    private static func makeTableRound(
        operation: MathOperation,
        table: Int,
        difficultyTier: Int
    ) -> [MathQuestion] {
        let otherFactors = ascendingOtherFactors(
            count: LearningRules.questionsPerRound,
            difficultyTier: difficultyTier
        )

        return otherFactors.map { otherFactor in
            makeTableQuestion(
                operation: operation,
                table: table,
                otherFactor: otherFactor,
                swapOperands: false
            )
        }
    }

    /// Tables in teaching order. Easy rounds: 2→6. Harder tiers shift later: 4→8, then 6→10.
    private static func ascendingTables(count: Int, difficultyTier: Int) -> [Int] {
        let cappedTier = min(max(difficultyTier, 1), 3)
        let startTable = min(lastTable, firstTable + (cappedTier - 1) * 2)
        return (0..<count).map { index in
            min(startTable + index, lastTable)
        }
    }

    /// Partner numbers in teaching order: 1→5 on easy rounds; later tiers shift upward.
    private static func ascendingOtherFactors(count: Int, difficultyTier: Int) -> [Int] {
        let cappedTier = min(max(difficultyTier, 1), 3)
        let start = 1 + (cappedTier - 1) * 2
        return (0..<count).map { index in
            min(start + index, 10)
        }
    }

    private static func factorPoolMax(for difficultyTier: Int) -> Int {
        switch difficultyTier {
        case 1: 5
        case 2: 8
        default: 10
        }
    }

    private static func makeQuestion(
        operation: MathOperation,
        firstFactor: Int,
        secondFactor: Int
    ) -> MathQuestion {
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
