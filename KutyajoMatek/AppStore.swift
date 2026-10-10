import Foundation
import UIKit

struct PersistedAppState: Codable, Equatable {
    var profiles: [PlayerProfile]
    var progressByProfile: [String: PlayerProgress]
    var selectedProfileID: String?
}

@MainActor
final class AppStore: ObservableObject {
    @Published var selectedProfile: PlayerProfile?
    @Published private(set) var profiles: [PlayerProfile]
    @Published private(set) var progressByProfile: [String: PlayerProgress]
    @Published private(set) var languagePreference: AppLanguagePreference

    private let defaults: UserDefaults
    private let stateKey = "kutyajoMatek.appState.v2"
    private let migrationFlagKey = "kutyajoMatek.didMigrateProfiles.v2"
    private let languageKey = "kutyajoMatek.languagePreference.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if
            let raw = defaults.string(forKey: languageKey),
            let savedLanguage = AppLanguagePreference(rawValue: raw)
        {
            languagePreference = savedLanguage
        } else {
            languagePreference = .system
        }

        let shouldPersistMigratedState: Bool
        if
            let data = defaults.data(forKey: stateKey),
            let saved = try? JSONDecoder().decode(PersistedAppState.self, from: data)
        {
            profiles = saved.profiles
            progressByProfile = saved.progressByProfile
            selectedProfile = saved.profiles.first { $0.id == saved.selectedProfileID }
            defaults.set(true, forKey: migrationFlagKey)
            shouldPersistMigratedState = false
        } else {
            let migrated = Self.migrateLegacyIfNeeded(defaults: defaults)
            profiles = migrated.profiles
            progressByProfile = migrated.progressByProfile
            selectedProfile = nil
            shouldPersistMigratedState = true
        }

        LanguageSettings.apply(languagePreference)
        if shouldPersistMigratedState {
            persist()
        }
    }

    var hasProfiles: Bool { !profiles.isEmpty }

    var resolvedLocale: Locale { languagePreference.resolvedLocale }

    func setLanguagePreference(_ preference: AppLanguagePreference) {
        languagePreference = preference
        LanguageSettings.apply(preference)
        defaults.set(preference.rawValue, forKey: languageKey)
    }

    func profile(id: String) -> PlayerProfile? {
        profiles.first { $0.id == id }
    }

    func progress(for profile: PlayerProfile) -> PlayerProgress {
        progressByProfile[profile.id] ?? PlayerProgress()
    }

    func learningPath(for profile: PlayerProfile, operation: MathOperation) -> OperationPathProgress {
        progress(for: profile).learning.path(for: operation)
    }

    func difficultyTier(for profile: PlayerProfile, operation: MathOperation, level: LearningLevel) -> Int {
        learningPath(for: profile, operation: operation).difficultyTier(for: level)
    }

    @discardableResult
    func createProfile(name: String, avatarImage: UIImage? = nil) -> PlayerProfile {
        var profile = PlayerProfile.makeNew(name: name, accentIndex: profiles.count)
        if let avatarImage, let fileName = try? ProfileAvatarStore.saveImage(avatarImage, forProfileID: profile.id) {
            profile.avatarFileName = fileName
        }
        profiles.append(profile)
        progressByProfile[profile.id] = PlayerProgress()
        selectedProfile = profile
        persist()
        return profile
    }

    func renameProfile(id: String, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[index].name = trimmed
        if selectedProfile?.id == id {
            selectedProfile = profiles[index]
        }
        persist()
    }

    func setAvatar(for id: String, image: UIImage?) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        let previous = profiles[index].avatarFileName

        if let image {
            if let fileName = try? ProfileAvatarStore.saveImage(image, forProfileID: id) {
                profiles[index].avatarFileName = fileName
                ProfileAvatarStore.deleteImage(fileName: previous)
            }
        } else {
            profiles[index].avatarFileName = nil
            ProfileAvatarStore.deleteImage(fileName: previous)
        }

        if selectedProfile?.id == id {
            selectedProfile = profiles[index]
        }
        persist()
    }

    func selectProfile(_ profile: PlayerProfile) {
        guard profiles.contains(where: { $0.id == profile.id }) else { return }
        selectedProfile = profile
        persist()
    }

    func clearSelectedProfile() {
        selectedProfile = nil
        persist()
    }

    /// Clears dogs, scores, and learning progress. Keeps name, id, and picture.
    func resetProgress(for id: String) {
        guard profiles.contains(where: { $0.id == id }) else { return }
        progressByProfile[id] = PlayerProgress()
        persist()
    }

    /// Permanently removes the profile, progress, and stored picture.
    func deleteProfile(id: String) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        let removed = profiles.remove(at: index)
        progressByProfile[id] = nil
        ProfileAvatarStore.deleteImage(fileName: removed.avatarFileName)

        if selectedProfile?.id == id {
            selectedProfile = nil
        }
        persist()
    }

    func recordAnswer(for profile: PlayerProfile, isCorrect: Bool) {
        guard isCorrect else { return }
        updateProgress(for: profile.id) { progress in
            progress.totalCorrectAnswers += 1
        }
    }

    func finishRound(for profile: PlayerProfile, perfect: Bool) -> RoundResult {
        var reward: Int?
        var lost: Int?

        updateProgress(for: profile.id) { progress in
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

    @discardableResult
    func finishLearningRound(
        for profile: PlayerProfile,
        operation: MathOperation,
        level: LearningLevel,
        correctCount: Int
    ) -> LearningRoundOutcome {
        let isMasteryQuality = LearningRules.isMasteryQuality(correctCount: correctCount)
        var unlockedLevel: LearningLevel?
        var masteredAllLevels = false

        updateProgress(for: profile.id) { progress in
            progress.learning.updatePath(for: operation) { path in
                guard level.number <= path.unlockedLevel else { return }

                if isMasteryQuality {
                    path.masteryWins[level.number - 1] += 1
                }

                let wins = path.masteryWins[level.number - 1]
                let canUnlockNext =
                    isMasteryQuality
                    && wins >= LearningRules.masteryRoundsRequired
                    && path.unlockedLevel == level.number
                    && level.number < LearningLevel.count

                if canUnlockNext {
                    path.unlockedLevel = level.number + 1
                    unlockedLevel = LearningLevel(number: level.number + 1)
                }

                masteredAllLevels =
                    level.number == LearningLevel.count
                    && path.masteryWins[level.number - 1] >= LearningRules.masteryRoundsRequired
            }
        }

        return LearningRoundOutcome(
            isMasteryQuality: isMasteryQuality,
            unlockedLevel: unlockedLevel,
            masteredAllLevels: masteredAllLevels
        )
    }

    private func updateProgress(for id: String, mutation: (inout PlayerProgress) -> Void) {
        var progress = progressByProfile[id] ?? PlayerProgress()
        mutation(&progress)
        progressByProfile[id] = progress
        persist()
    }

    private func persist() {
        let state = PersistedAppState(
            profiles: profiles,
            progressByProfile: progressByProfile,
            selectedProfileID: selectedProfile?.id
        )
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: stateKey)
        defaults.set(true, forKey: migrationFlagKey)
    }

    /// One-time migration from the previous progress-only store into profile records.
    private static func migrateLegacyIfNeeded(defaults: UserDefaults) -> PersistedAppState {
        let alreadyMigrated = defaults.bool(forKey: "kutyajoMatek.didMigrateProfiles.v2")
        let legacyProgress = loadLegacyProgress(from: defaults)

        if alreadyMigrated {
            return PersistedAppState(profiles: [], progressByProfile: [:], selectedProfileID: nil)
        }

        var profiles: [PlayerProfile] = []
        var progressByProfile: [String: PlayerProgress] = legacyProgress

        let legacySeeds: [(id: String, profile: PlayerProfile)] = [
            (PlayerProfile.legacyIzabellaID, .izabella),
            (PlayerProfile.legacyLauraID, .laura)
        ]

        for seed in legacySeeds where legacyProgress[seed.id] != nil {
            profiles.append(seed.profile)
        }

        defaults.set(true, forKey: "kutyajoMatek.didMigrateProfiles.v2")
        return PersistedAppState(
            profiles: profiles,
            progressByProfile: progressByProfile,
            selectedProfileID: nil
        )
    }

    private static func loadLegacyProgress(from defaults: UserDefaults) -> [String: PlayerProgress] {
        let keys = ["kutyajoMatek.progress.v1", "dogMath.progress.v1"]
        for key in keys {
            if
                let data = defaults.data(forKey: key),
                let saved = try? JSONDecoder().decode([String: PlayerProgress].self, from: data)
            {
                return saved
            }
        }
        return [:]
    }
}

struct RoundResult: Equatable {
    let rewardDogID: Int?
    let lostDogID: Int?
}
