import XCTest
@testable import KutyajoMatek

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

    func testMixedRoundAlternatesOperationsAndUsesAscendingTables() {
        let questions = QuestionFactory.makeRound(mode: .mixed)
        XCTAssertEqual(questions.map(\.operation), [
            .multiplication, .division, .multiplication, .division, .multiplication
        ])

        // Easy mixed rounds teach tables in order: 2, 3, 4, 5, 6 — not random hard pairs.
        XCTAssertEqual(questions.map(\.tableFactor), [2, 3, 4, 5, 6])
        XCTAssertEqual(questions.map(\.otherFactor), [1, 2, 3, 4, 5])
    }

    func testOpenMultiplicationAndDivisionFollowAscendingTableOrder() {
        let multiplication = QuestionFactory.makeRound(mode: .multiplication)
        XCTAssertEqual(multiplication.map(\.operation), Array(repeating: .multiplication, count: 5))
        XCTAssertEqual(multiplication.map(\.tableFactor), [2, 3, 4, 5, 6])
        XCTAssertEqual(multiplication.map(\.left), [2, 3, 4, 5, 6])

        let division = QuestionFactory.makeRound(mode: .division)
        XCTAssertEqual(division.map(\.operation), Array(repeating: .division, count: 5))
        XCTAssertEqual(division.map(\.tableFactor), [2, 3, 4, 5, 6])
        XCTAssertEqual(division.map(\.right), [2, 3, 4, 5, 6])
    }

    func testProgressiveMultiplicationUsesSelectedTableInOrder() {
        let level = LearningLevel(number: 3) // ×4
        let configuration = PracticeConfiguration.progressive(operation: .multiplication, level: level)
        let questions = QuestionFactory.makeRound(configuration: configuration, difficultyTier: 1)

        XCTAssertEqual(questions.map(\.operation), Array(repeating: .multiplication, count: 5))
        XCTAssertEqual(questions.map(\.left), Array(repeating: level.table, count: 5))
        XCTAssertEqual(questions.map(\.right), [1, 2, 3, 4, 5])
        for question in questions {
            XCTAssertEqual(question.left * question.right, question.answer)
        }
    }

    func testProgressiveDivisionUsesSelectedTableWithWholeAnswersInOrder() {
        let level = LearningLevel(number: 5) // ÷6
        let configuration = PracticeConfiguration.progressive(operation: .division, level: level)
        let questions = QuestionFactory.makeRound(configuration: configuration, difficultyTier: 1)

        XCTAssertEqual(questions.map(\.right), Array(repeating: level.table, count: 5))
        XCTAssertEqual(questions.map(\.answer), [1, 2, 3, 4, 5])
        for question in questions {
            XCTAssertEqual(question.operation, .division)
            XCTAssertEqual(question.left % question.right, 0)
            XCTAssertEqual(question.left / question.right, question.answer)
        }
    }

    func testEasyDifficultyKeepsOtherFactorWithinFive() {
        let level = LearningLevel(number: 1)
        let configuration = PracticeConfiguration.progressive(operation: .multiplication, level: level)
        let questions = QuestionFactory.makeRound(configuration: configuration, difficultyTier: 1)
        XCTAssertEqual(questions.map(\.otherFactor), [1, 2, 3, 4, 5])
    }

    func testHarderTierShiftsOtherFactorsUpwardWithoutRepeats() {
        let level = LearningLevel(number: 2)
        let configuration = PracticeConfiguration.progressive(operation: .division, level: level)
        let questions = QuestionFactory.makeRound(configuration: configuration, difficultyTier: 3)
        let factors = questions.map(\.answer)
        XCTAssertEqual(factors, [5, 6, 7, 8, 9])
        XCTAssertEqual(Set(factors).count, factors.count)
    }
}

private extension MathQuestion {
    /// The teaching-table factor (2...10) for ordered practice questions.
    var tableFactor: Int {
        switch operation {
        case .multiplication: left
        case .division: right
        }
    }

    var otherFactor: Int {
        switch operation {
        case .multiplication: right
        case .division: answer
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
            forKey: "kutyajoMatek.progress.v1"
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

    func testLegacyLauraAndIzabellaProfilesMigrateWithProgress() throws {
        let suiteName = "AppStoreMigrate.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let lauraProgress = PlayerProgress(collectedDogIDs: [3, 7], totalCorrectAnswers: 10, completedRounds: 2)
        let izabellaProgress = PlayerProgress(collectedDogIDs: [1], totalCorrectAnswers: 5, completedRounds: 1)
        defaults.set(
            try JSONEncoder().encode([
                PlayerProfile.legacyLauraID: lauraProgress,
                PlayerProfile.legacyIzabellaID: izabellaProgress
            ]),
            forKey: "kutyajoMatek.progress.v1"
        )

        let store = AppStore(defaults: defaults)
        XCTAssertEqual(store.profiles.map(\.id).sorted(), [
            PlayerProfile.legacyIzabellaID,
            PlayerProfile.legacyLauraID
        ].sorted())
        XCTAssertEqual(store.progress(for: .laura).collectedDogIDs, [3, 7])
        XCTAssertEqual(store.progress(for: .izabella).collectedDogIDs, [1])

        store.deleteProfile(id: PlayerProfile.legacyLauraID)
        XCTAssertFalse(store.profiles.contains { $0.id == PlayerProfile.legacyLauraID })

        let reloaded = AppStore(defaults: defaults)
        XCTAssertFalse(reloaded.profiles.contains { $0.id == PlayerProfile.legacyLauraID })
        XCTAssertEqual(reloaded.profiles.map(\.id), [PlayerProfile.legacyIzabellaID])
        XCTAssertEqual(reloaded.progress(for: .izabella).collectedDogIDs, [1])
    }

    func testRenameKeepsProgressAndResetClearsOnlyGameplay() throws {
        let suiteName = "AppStoreRenameReset.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AppStore(defaults: defaults)
        let created = store.createProfile(name: "Izabella")
        _ = store.finishRound(for: created, perfect: true)
        XCTAssertEqual(store.progress(for: created).collectedDogIDs.count, 1)

        store.renameProfile(id: created.id, to: "Iza")
        let renamed = try XCTUnwrap(store.profile(id: created.id))
        XCTAssertEqual(renamed.name, "Iza")
        XCTAssertEqual(renamed.id, created.id)
        XCTAssertEqual(store.progress(for: renamed).collectedDogIDs.count, 1)

        store.resetProgress(for: created.id)
        let afterReset = try XCTUnwrap(store.profile(id: created.id))
        XCTAssertEqual(afterReset.name, "Iza")
        XCTAssertEqual(store.progress(for: afterReset).collectedDogIDs, [])
        XCTAssertEqual(store.progress(for: afterReset).completedRounds, 0)
        XCTAssertEqual(store.progress(for: afterReset).learning.multiplication.unlockedLevel, 1)
    }

    func testDeleteProfileDoesNotAffectOtherProfilesAndPersists() {
        let suiteName = "AppStoreDelete.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AppStore(defaults: defaults)
        let first = store.createProfile(name: "Laura")
        let second = store.createProfile(name: "Izabella")
        _ = store.finishRound(for: first, perfect: true)
        _ = store.finishRound(for: second, perfect: true)

        store.selectProfile(first)
        store.deleteProfile(id: first.id)

        XCTAssertNil(store.selectedProfile)
        XCTAssertEqual(store.profiles.map(\.id), [second.id])
        XCTAssertEqual(store.progress(for: second).collectedDogIDs.count, 1)
        XCTAssertTrue(store.progress(for: first).collectedDogIDs.isEmpty)

        let reloaded = AppStore(defaults: defaults)
        XCTAssertEqual(reloaded.profiles.map(\.id), [second.id])
        XCTAssertEqual(reloaded.progress(for: second).collectedDogIDs.count, 1)
        XCTAssertFalse(reloaded.profiles.contains { $0.id == first.id })
    }

    func testMigrationDoesNotRecreateProfilesAfterFreshEmptyLaunch() {
        let suiteName = "AppStoreNoReseed.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstLaunch = AppStore(defaults: defaults)
        XCTAssertTrue(firstLaunch.profiles.isEmpty)

        let secondLaunch = AppStore(defaults: defaults)
        XCTAssertTrue(secondLaunch.profiles.isEmpty)
    }
}
