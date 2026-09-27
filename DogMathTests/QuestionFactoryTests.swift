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
                XCTAssertEqual(questions.count, 5)

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
}
