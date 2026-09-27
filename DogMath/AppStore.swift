import Foundation

@MainActor
final class AppStore: ObservableObject {
    @Published var selectedProfile: PlayerProfile?
    @Published private(set) var progressByProfile: [String: PlayerProgress]

    private let defaults: UserDefaults
    private let storageKey = "dogMath.progress.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if
            let data = defaults.data(forKey: storageKey),
            let saved = try? JSONDecoder().decode([String: PlayerProgress].self, from: data)
        {
            progressByProfile = saved
        } else {
            progressByProfile = [:]
        }
    }

    func progress(for profile: PlayerProfile) -> PlayerProgress {
        progressByProfile[profile.id] ?? PlayerProgress()
    }

    func recordAnswer(for profile: PlayerProfile, isCorrect: Bool) {
        guard isCorrect else { return }
        update(profile) { progress in
            progress.totalCorrectAnswers += 1
        }
    }

    func finishRound(for profile: PlayerProfile, perfect: Bool) -> RoundResult {
        var reward: Int?
        var lost: Int?

        update(profile) { progress in
            progress.completedRounds += 1

            if perfect {
                let locked = Set(0..<DogCatalog.count).subtracting(progress.collectedDogIDs)
                reward = locked.randomElement()
                if let reward {
                    progress.collectedDogIDs.append(reward)
                }
            } else {
                progress.failedRounds += 1
                if progress.failedRounds >= 3 {
                    progress.failedRounds = 0
                    lost = progress.collectedDogIDs.randomElement()
                    if let lost {
                        progress.collectedDogIDs.removeAll { $0 == lost }
                    }
                }
            }
        }

        return RoundResult(rewardDogID: reward, lostDogID: lost)
    }

    private func update(_ profile: PlayerProfile, mutation: (inout PlayerProgress) -> Void) {
        var progress = self.progress(for: profile)
        mutation(&progress)
        progressByProfile[profile.id] = progress
        save()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(progressByProfile) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

struct RoundResult: Equatable {
    let rewardDogID: Int?
    let lostDogID: Int?
}
