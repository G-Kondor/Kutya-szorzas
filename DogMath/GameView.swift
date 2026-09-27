import SwiftUI
import UIKit

struct GameView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let profile: PlayerProfile
    let mode: GameMode

    @State private var questions: [MathQuestion]
    @State private var currentIndex = 0
    @State private var selectedAnswer: Int?
    @State private var correctCount = 0
    @State private var madeMistake = false
    @State private var result: RoundResult?
    @State private var isShowingSummary = false

    init(profile: PlayerProfile, mode: GameMode) {
        self.profile = profile
        self.mode = mode
        _questions = State(initialValue: QuestionFactory.makeRound(mode: mode))
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
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled(selectedAnswer != nil)
        .sheet(isPresented: $isShowingSummary) {
            RoundSummaryView(
                profile: profile,
                correctCount: correctCount,
                result: result ?? RoundResult(rewardDogID: nil, lostDogID: nil),
                onPlayAgain: startNewRound,
                onFinish: { dismiss() }
            )
            .interactiveDismissDisabled()
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Label("\(currentIndex + 1) / 5", systemImage: "list.number")
                Spacer()
                Label("\(correctCount)", systemImage: "star.fill")
                    .foregroundStyle(AppTheme.pink)
            }
            .font(.system(.headline, design: .rounded, weight: .bold))

            ProgressView(value: Double(currentIndex + 1), total: 5)
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
                .accessibilityLabel(question.prompt.replacingOccurrences(of: "×", with: "szorozva").replacingOccurrences(of: "÷", with: "osztva"))
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
                isCorrect ? "Szuper! Ez talált!" : "Majdnem! A helyes válasz: \(question.answer)",
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
            result = store.finishRound(for: profile, perfect: !madeMistake && correctCount == 5)
            isShowingSummary = true
        }
    }

    private func startNewRound() {
        questions = QuestionFactory.makeRound(mode: mode)
        currentIndex = 0
        selectedAnswer = nil
        correctCount = 0
        madeMistake = false
        result = nil
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
    let onPlayAgain: () -> Void
    let onFinish: () -> Void

    private var isPerfect: Bool { correctCount == 5 }

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
                    Text("Ő \(DogCatalog.name(for: dogID))!")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(AppTheme.pink)
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

                Text("\(correctCount) / 5 helyes válasz")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(profile.tint)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.82), in: Capsule())

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
        if result.rewardDogID != nil { return "Hibátlan kör! Új kutyus érkezett!" }
        if isPerfect { return "Fantasztikus! Mind a 40 kutyus a tiéd!" }
        if let lostID = result.lostDogID { return "Most \(DogCatalog.name(for: lostID)) elbúcsúzott" }
        return "Szép próbálkozás!"
    }

    private var summaryMessage: String {
        if result.rewardDogID != nil { return "Öt jó válasz egymás után — megérdemelted az új barátodat." }
        if isPerfect { return "A teljes kutyagyűjteményt megszerezted. Ez óriási teljesítmény!" }
        if result.lostDogID != nil { return "Ez volt a harmadik elrontott kör, ezért egy kutyus visszakerült a gyűjteménybe. A következő körben újra megszerezheted!" }
        return "Semmi baj: minden körrel ügyesebb leszel. Három elrontott kör után elveszíthetsz egy kutyust." 
    }
}
