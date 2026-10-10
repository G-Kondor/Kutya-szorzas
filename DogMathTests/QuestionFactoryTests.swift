import XCTest
@testable import Kutyaszorzas

final class QuestionFactoryTests: XCTestCase {
    func testAllFortyDogPortraitsAreBundled() {
        for dogID in 0..<DogCatalog.count {
            XCTAssertNotNil(DogImageLoader.image(for: dogID), "Missing dog portrait \(dogID + 1)")
        }
    }

    func testGeneratedQuestionsStayInsideTheHundredRange() {
        for mode in GameMode.allCases {
            for _ in 0..<100 {
                let questions = QuestionFactory.makeRound(mode: mode)
                XCTAssertEqual(questions.count, LearningRules.questionsPerRound)

                for question in questions {
                    XCTAssertTrue((0...100).contains(question.answer))
                    XCTAssertEqual(question.choices.count, 3)
                    XCTAssertEqual(Set(question.choices).count, 3)
                    XCTAssertTrue(question.choices.contains(question.answer))

                    switch question.operation {
                    case .multiplication:
                        XCTAssertEqual(question.left * question.right, question.answer)
                    case .division:
                        XCTAssertEqual(question.left / question.right, question.answer)
                        XCTAssertEqual(question.left % question.right, 0)
                    }
                }
            }
        }
    }

    func testMixedRoundAlternatesOperations() {
        let questions = QuestionFactory.makeRound(mode: .mixed)
        XCTAssertEqual(questions.map(\.operation), [
            .multiplication, .division, .multiplication, .division, .multiplication
        ])
    }

    func testProgressiveMultiplicationUsesSelectedTable() {
        let level = LearningLevel(number: 3) // ×4
        let configuration = PracticeConfiguration.progressive(operation: .multiplication, level: level)

        for tier in 1...3 {
            for _ in 0..<40 {
                let questions = QuestionFactory.makeRound(configuration: configuration, difficultyTier: tier)
                XCTAssertEqual(questions.count, 5)

                for question in questions {
                    XCTAssertEqual(question.operation, .multiplication)
                    XCTAssertTrue(
                        question.left == level.table || question.right == level.table,
                        "Expected table \(level.table) in \(question.prompt)"
                    )
                    XCTAssertEqual(question.left * question.right, question.answer)
                    XCTAssertLessThanOrEqual(question.answer, 100)
                }
            }
        }
    }

    func testProgressiveDivisionUsesSelectedTableWithWholeAnswers() {
        let level = LearningLevel(number: 5) // ÷6
        let configuration = PracticeConfiguration.progressive(operation: .division, level: level)

        for tier in 1...3 {
            for _ in 0..<40 {
                let questions = QuestionFactory.makeRound(configuration: configuration, difficultyTier: tier)
                XCTAssertEqual(questions.count, 5)

                for question in questions {
                    XCTAssertEqual(question.operation, .division)
                    XCTAssertEqual(question.right, level.table)
                    XCTAssertEqual(question.left % question.right, 0)
                    XCTAssertEqual(question.left / question.right, question.answer)
                    XCTAssertTrue((1...10).contains(question.answer))
                }
            }
        }
    }

    func testEasyDifficultyKeepsOtherFactorWithinFive() {
        let level = LearningLevel(number: 1)
        let configuration = PracticeConfiguration.progressive(operation: .multiplication, level: level)

        for _ in 0..<50 {
            let questions = QuestionFactory.makeRound(configuration: configuration, difficultyTier: 1)
            for question in questions {
                let other = question.left == level.table ? question.right : question.left
                XCTAssertTrue((1...5).contains(other), "Unexpected factor \(other) at easy tier")
            }
        }
    }

    func testRoundAvoidsRepeatingTheSameOtherFactorWhenPossible() {
        let level = LearningLevel(number: 2)
        let configuration = PracticeConfiguration.progressive(operation: .division, level: level)

        for _ in 0..<30 {
            let questions = QuestionFactory.makeRound(configuration: configuration, difficultyTier: 3)
            let factors = questions.map(\.answer)
            XCTAssertEqual(Set(factors).count, factors.count)
        }
    }
}

final class LearningProgressTests: XCTestCase {
    func testMasteryThresholdRequiresFourOfFive() {
        XCTAssertEqual(LearningRules.minimumCorrectForMastery, 4)
        XCTAssertFalse(LearningRules.isMasteryQuality(correctCount: 3))
        XCTAssertTrue(LearningRules.isMasteryQuality(correctCount: 4))
        XCTAssertTrue(LearningRules.isMasteryQuality(correctCount: 5))
    }

    func testLevelStatusTransitions() {
        var path = OperationPathProgress(unlockedLevel: 2, masteryWins: [2, 0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(path.status(for: LearningLevel(number: 1)), .completed)
        XCTAssertEqual(path.status(for: LearningLevel(number: 2)), .current)
        XCTAssertEqual(path.status(for: LearningLevel(number: 3)), .locked)

        path.masteryWins[1] = 2
        path.unlockedLevel = 3
        XCTAssertEqual(path.status(for: LearningLevel(number: 2)), .completed)
        XCTAssertEqual(path.status(for: LearningLevel(number: 3)), .current)
    }

    func testDifficultyTierGrowsWithMasteryWins() {
        let path = OperationPathProgress(unlockedLevel: 1, masteryWins: [0, 0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(path.difficultyTier(for: LearningLevel(number: 1)), 1)

        let mid = OperationPathProgress(unlockedLevel: 1, masteryWins: [1, 0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(mid.difficultyTier(for: LearningLevel(number: 1)), 2)

        let hard = OperationPathProgress(unlockedLevel: 1, masteryWins: [5, 0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(hard.difficultyTier(for: LearningLevel(number: 1)), 3)
    }

    func testLegacyProgressDecodingWithoutLearningField() throws {
        let legacyJSON = """
        {
          "laura": {
            "collectedDogIDs": [1, 2],
            "failedRounds": 1,
            "totalCorrectAnswers": 8,
            "completedRounds": 3
          }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode([String: PlayerProgress].self, from: legacyJSON)
        let progress = try XCTUnwrap(decoded["laura"])
        XCTAssertEqual(progress.collectedDogIDs, [1, 2])
        XCTAssertEqual(progress.learning.multiplication.unlockedLevel, 1)
        XCTAssertEqual(progress.learning.division.unlockedLevel, 1)
        XCTAssertEqual(progress.learning.multiplication.masteryWins.count, LearningLevel.count)
    }
}

@MainActor
final class AppStoreTests: XCTestCase {
    func testThirdFailedRoundRemovesAnOwnedDog() {
        let suiteName = "AppStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AppStore(defaults: defaults)
        let profile = PlayerProfile.laura

        let reward = store.finishRound(for: profile, perfect: true)
        XCTAssertNotNil(reward.rewardDogID)
        XCTAssertEqual(store.progress(for: profile).collectedDogIDs.count, 1)

        XCTAssertNil(store.finishRound(for: profile, perfect: false).lostDogID)
        XCTAssertNil(store.finishRound(for: profile, perfect: false).lostDogID)
        let thirdFailure = store.finishRound(for: profile, perfect: false)

        XCTAssertNotNil(thirdFailure.lostDogID)
        XCTAssertTrue(store.progress(for: profile).collectedDogIDs.isEmpty)
        XCTAssertEqual(store.progress(for: profile).failedRounds, 0)
    }

    func testLearningPathsProgressIndependentlyAndPersist() {
        let suiteName = "AppStoreLearning.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AppStore(defaults: defaults)
        let profile = PlayerProfile.izabella
        let level1 = LearningLevel(number: 1)

        let first = store.finishLearningRound(
            for: profile,
            operation: .multiplication,
            level: level1,
            correctCount: 4
        )
        XCTAssertTrue(first.isMasteryQuality)
        XCTAssertNil(first.unlockedLevel)

        let second = store.finishLearningRound(
            for: profile,
            operation: .multiplication,
            level: level1,
            correctCount: 5
        )
        XCTAssertEqual(second.unlockedLevel?.number, 2)
        XCTAssertEqual(store.learningPath(for: profile, operation: .multiplication).unlockedLevel, 2)
        XCTAssertEqual(store.learningPath(for: profile, operation: .division).unlockedLevel, 1)

        let reloaded = AppStore(defaults: defaults)
        XCTAssertEqual(reloaded.learningPath(for: profile, operation: .multiplication).unlockedLevel, 2)
        XCTAssertEqual(reloaded.learningPath(for: profile, operation: .multiplication).masteryWins(for: level1), 2)
        XCTAssertEqual(reloaded.learningPath(for: profile, operation: .division).unlockedLevel, 1)
    }

    func testWeakRoundDoesNotCountTowardUnlock() {
        let suiteName = "AppStoreWeak.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AppStore(defaults: defaults)
        let profile = PlayerProfile.laura
        let level1 = LearningLevel(number: 1)

        _ = store.finishLearningRound(for: profile, operation: .division, level: level1, correctCount: 5)
        let weak = store.finishLearningRound(for: profile, operation: .division, level: level1, correctCount: 3)

        XCTAssertFalse(weak.isMasteryQuality)
        XCTAssertNil(weak.unlockedLevel)
        XCTAssertEqual(store.learningPath(for: profile, operation: .division).unlockedLevel, 1)
        XCTAssertEqual(store.learningPath(for: profile, operation: .division).masteryWins(for: level1), 1)
    }

    func testLockedLevelProgressIsIgnored() {
        let suiteName = "AppStoreLocked.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AppStore(defaults: defaults)
        let profile = PlayerProfile.laura
        let locked = LearningLevel(number: 4)

        let outcome = store.finishLearningRound(
            for: profile,
            operation: .multiplication,
            level: locked,
            correctCount: 5
        )

        XCTAssertNil(outcome.unlockedLevel)
        XCTAssertEqual(store.learningPath(for: profile, operation: .multiplication).unlockedLevel, 1)
        XCTAssertEqual(store.learningPath(for: profile, operation: .multiplication).masteryWins(for: locked), 0)
    }

    func testFinalLevelMasteryMarksPathComplete() throws {
        let suiteName = "AppStoreFinal.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let profile = PlayerProfile.laura
        let finalLevel = LearningLevel(number: LearningLevel.count)
        let forced = PlayerProgress(
            learning: LearningProgress(
                multiplication: OperationPathProgress(),
                division: OperationPathProgress(
                    unlockedLevel: LearningLevel.count,
                    masteryWins: Array(repeating: 2, count: LearningLevel.count - 1) + [0]
                )
            )
        )
        defaults.set(
            try JSONEncoder().encode([profile.id: forced]),
            forKey: "dogMath.progress.v1"
        )

        let store = AppStore(defaults: defaults)
        let first = store.finishLearningRound(
            for: profile,
            operation: .division,
            level: finalLevel,
            correctCount: 4
        )
        XCTAssertFalse(first.masteredAllLevels)

        let second = store.finishLearningRound(
            for: profile,
            operation: .division,
            level: finalLevel,
            correctCount: 5
        )
        XCTAssertTrue(second.masteredAllLevels)
        XCTAssertNil(second.unlockedLevel)
        XCTAssertEqual(store.learningPath(for: profile, operation: .division).unlockedLevel, LearningLevel.count)
    }
}
