import SwiftUI
import UIKit

struct GameView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let profile: PlayerProfile
    let configuration: PracticeConfiguration

    @State private var questions: [MathQuestion]
    @State private var currentIndex = 0
    @State private var selectedAnswer: Int?
    @State private var correctCount = 0
    @State private var madeMistake = false
    @State private var result: RoundResult?
    @State private var learningOutcome: LearningRoundOutcome?
    @State private var isShowingSummary = false
    @State private var difficultyTier: Int

    init(profile: PlayerProfile, configuration: PracticeConfiguration, difficultyTier: Int = 1) {
        self.profile = profile
        self.configuration = configuration
        self._difficultyTier = State(initialValue: difficultyTier)
        _questions = State(
            initialValue: QuestionFactory.makeRound(
                configuration: configuration,
                difficultyTier: difficultyTier
            )
        )
    }

    /// Backward-compatible entry for mixed or open practice by mode alone.
    init(profile: PlayerProfile, mode: GameMode) {
        self.init(profile: profile, configuration: PracticeConfiguration(mode: mode, level: nil))
    }

    private var question: MathQuestion {
        questions[currentIndex]
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 22) {
                progressHeader
                questionCard
                choices
                feedbackArea
                Spacer(minLength: 12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .navigationTitle(configuration.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(selectedAnswer != nil)
        .sheet(isPresented: $isShowingSummary) {
            RoundSummaryView(
                profile: profile,
                correctCount: correctCount,
                result: result ?? RoundResult(rewardDogID: nil, lostDogID: nil),
                learningOutcome: learningOutcome,
                configuration: configuration,
                onPlayAgain: startNewRound,
                onFinish: { dismiss() }
            )
            .interactiveDismissDisabled()
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Label("\(currentIndex + 1) / \(LearningRules.questionsPerRound)", systemImage: "list.number")
                Spacer()
                Label("\(correctCount)", systemImage: "star.fill")
                    .foregroundStyle(AppTheme.pink)
            }
            .font(.system(.headline, design: .rounded, weight: .bold))

            ProgressView(value: Double(currentIndex + 1), total: Double(LearningRules.questionsPerRound))
                .tint(profile.tint)
                .scaleEffect(x: 1, y: 1.8)
        }
        .foregroundStyle(AppTheme.ink)
    }

    private var questionCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 7) {
                Image(systemName: "pawprint.fill")
                Text("Melyik a jó válasz?")
            }
            .font(.system(.subheadline, design: .rounded, weight: .bold))
            .foregroundStyle(AppTheme.lavender)

            Text(question.prompt)
                .font(.system(size: 47, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.7)
                .foregroundStyle(AppTheme.ink)
                .accessibilityLabel(
                    question.prompt
                        .replacingOccurrences(of: "×", with: L10n.spokenTimes())
                        .replacingOccurrences(of: "÷", with: L10n.spokenDivided())
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 18)
        .softCard()
    }

    private var choices: some View {
        VStack(spacing: 12) {
            ForEach(question.choices, id: \.self) { choice in
                Button {
                    select(choice)
                } label: {
                    HStack {
                        Text("\(choice)")
                            .font(.system(size: 29, weight: .bold, design: .rounded))
                        Spacer()
                        if let icon = answerIcon(for: choice) {
                            Image(systemName: icon)
                                .font(.title2.bold())
                        }
                    }
                    .foregroundStyle(answerForeground(for: choice))
                    .padding(.horizontal, 22)
                    .frame(maxWidth: .infinity, minHeight: 66)
                    .background(answerBackground(for: choice), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(answerBorder(for: choice), lineWidth: 2)
                    }
                    .shadow(color: AppTheme.lavender.opacity(0.1), radius: 10, y: 5)
                }
                .buttonStyle(.plain)
                .disabled(selectedAnswer != nil)
                .accessibilityLabel("\(choice)")
            }
        }
    }

    @ViewBuilder
    private var feedbackArea: some View {
        if let selectedAnswer {
            let isCorrect = selectedAnswer == question.answer
            Label(
                isCorrect ? L10n.text("Szuper! Ez talált!") : L10n.almostCorrect(answer: question.answer),
                systemImage: isCorrect ? "checkmark.circle.fill" : "heart.fill"
            )
            .font(.system(.headline, design: .rounded, weight: .bold))
            .foregroundStyle(isCorrect ? AppTheme.mint : AppTheme.pink)
            .transition(.scale.combined(with: .opacity))
        } else {
            Text("Válassz a három lehetőség közül!")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private func select(_ choice: Int) {
        guard selectedAnswer == nil else { return }
        let isCorrect = choice == question.answer

        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            selectedAnswer = choice
            if isCorrect {
                correctCount += 1
            } else {
                madeMistake = true
            }
        }

        store.recordAnswer(for: profile, isCorrect: isCorrect)
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(isCorrect ? .success : .error)

        Task {
            try? await Task.sleep(for: .milliseconds(850))
            advanceOrFinish()
        }
    }

    private func advanceOrFinish() {
        if currentIndex < questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.22)) {
                currentIndex += 1
                selectedAnswer = nil
            }
        } else {
            let perfect = !madeMistake && correctCount == LearningRules.questionsPerRound
            result = store.finishRound(for: profile, perfect: perfect)

            if let level = configuration.level, let operation = configuration.operation {
                learningOutcome = store.finishLearningRound(
                    for: profile,
                    operation: operation,
                    level: level,
                    correctCount: correctCount
                )
            } else {
                learningOutcome = nil
            }

            isShowingSummary = true
        }
    }

    private func startNewRound() {
        if let level = configuration.level, let operation = configuration.operation {
            difficultyTier = store.difficultyTier(for: profile, operation: operation, level: level)
        }

        questions = QuestionFactory.makeRound(
            configuration: configuration,
            difficultyTier: difficultyTier
        )
        currentIndex = 0
        selectedAnswer = nil
        correctCount = 0
        madeMistake = false
        result = nil
        learningOutcome = nil
        isShowingSummary = false
    }

    private func answerIcon(for choice: Int) -> String? {
        guard selectedAnswer != nil else { return nil }
        if choice == question.answer { return "checkmark.circle.fill" }
        if choice == selectedAnswer { return "xmark.circle.fill" }
        return nil
    }

    private func answerForeground(for choice: Int) -> Color {
        guard selectedAnswer != nil else { return AppTheme.ink }
        if choice == question.answer { return .white }
        if choice == selectedAnswer { return .white }
        return AppTheme.ink.opacity(0.45)
    }

    private func answerBackground(for choice: Int) -> Color {
        guard selectedAnswer != nil else { return .white.opacity(0.9) }
        if choice == question.answer { return AppTheme.mint }
        if choice == selectedAnswer { return AppTheme.pink }
        return .white.opacity(0.55)
    }

    private func answerBorder(for choice: Int) -> Color {
        guard selectedAnswer != nil else { return .white }
        if choice == question.answer { return AppTheme.mint }
        if choice == selectedAnswer { return AppTheme.pink }
        return .clear
    }
}

private struct RoundSummaryView: View {
    let profile: PlayerProfile
    let correctCount: Int
    let result: RoundResult
    let learningOutcome: LearningRoundOutcome?
    let configuration: PracticeConfiguration
    let onPlayAgain: () -> Void
    let onFinish: () -> Void

    private var isPerfect: Bool { correctCount == LearningRules.questionsPerRound }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                if let dogID = result.rewardDogID {
                    DogPortrait(id: dogID)
                        .frame(width: 210, height: 235)
                        .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 36))
                        .clipShape(RoundedRectangle(cornerRadius: 36))
                    Text(L10n.meetDog(DogCatalog.name(for: dogID)))
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(AppTheme.pink)
                } else if learningOutcome?.unlockedLevel != nil || learningOutcome?.masteredAllLevels == true {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 92, weight: .bold))
                        .foregroundStyle(AppTheme.peach)
                } else {
                    Image(systemName: isPerfect ? "trophy.fill" : "heart.circle.fill")
                        .font(.system(size: 92, weight: .bold))
                        .foregroundStyle(isPerfect ? AppTheme.peach : AppTheme.lavender)
                }

                Text(summaryTitle)
                    .font(.system(size: 31, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .multilineTextAlignment(.center)

                Text(summaryMessage)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text(L10n.correctAnswers(correctCount, total: LearningRules.questionsPerRound))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(profile.tint)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.82), in: Capsule())

                if let level = configuration.level, let operation = configuration.operation {
                    Text(level.shortLabel(for: operation))
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.lavender)
                }

                Spacer()

                Button(action: onPlayAgain) {
                    Label("Még egy kör", systemImage: "arrow.clockwise")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .foregroundStyle(.white)
                        .background(profile.tint, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)

                Button("Vissza a kezdőlapra", action: onFinish)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                    .frame(minHeight: 48)
            }
            .padding(24)
        }
    }

    private var summaryTitle: String {
        if let unlocked = learningOutcome?.unlockedLevel, let operation = configuration.operation {
            return L10n.levelUnlocked(unlocked.shortLabel(for: operation))
        }
        if learningOutcome?.masteredAllLevels == true {
            return L10n.text("Minden szint megvan!")
        }
        if result.rewardDogID != nil { return L10n.text("Hibátlan kör! Új kutyus érkezett!") }
        if isPerfect { return L10n.text("Fantasztikus! Mind a 40 kutyus a tiéd!") }
        if let lostID = result.lostDogID { return L10n.dogSaidGoodbye(DogCatalog.name(for: lostID)) }
        if learningOutcome?.isMasteryQuality == true { return L10n.text("Ügyes kör!") }
        return L10n.text("Szép próbálkozás!")
    }

    private var summaryMessage: String {
        if let unlocked = learningOutcome?.unlockedLevel, let operation = configuration.operation {
            return L10n.practiceUnlocked(unlocked.title(for: operation))
        }
        if learningOutcome?.masteredAllLevels == true {
            return L10n.text("Végigvitted az egész tanulóutat. Büszkék lehettek rád a kutyusok is!")
        }
        if result.rewardDogID != nil {
            return L10n.text("Öt jó válasz egymás után — megérdemelted az új barátodat.")
        }
        if isPerfect {
            return L10n.text("A teljes kutyagyűjteményt megszerezted. Ez óriási teljesítmény!")
        }
        if result.lostDogID != nil {
            return L10n.text("Ez volt a harmadik elrontott kör, ezért egy kutyus visszakerült a gyűjteménybe. A következő körben újra megszerezheted!")
        }
        if learningOutcome?.isMasteryQuality == true {
            return L10n.text("Legalább 4 jó válasz — így közelebb kerültél a következő szinthez. Hajrá!")
        }
        return L10n.text("Semmi baj: minden körrel ügyesebb leszel. Három elrontott kör után elveszíthetsz egy kutyust.")
    }
}
