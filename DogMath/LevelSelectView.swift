import SwiftUI

struct LevelSelectView: View {
    @EnvironmentObject private var store: AppStore
    let profile: PlayerProfile
    let operation: MathOperation

    private var path: OperationPathProgress {
        store.learningPath(for: profile, operation: operation)
    }

    private var accent: Color {
        operation == .multiplication ? AppTheme.pink : AppTheme.lavender
    }

    private var title: String {
        operation == .multiplication ? "Szorzás szintjei" : "Osztás szintjei"
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    headerCard
                    levelsList
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tanulj lépésről lépésre")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text("Két ügyes kör (legalább 4 jó válasz) nyitja ki a következő szintet. A vegyes játék bármikor elérhető.")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
            HStack(spacing: 14) {
                legendDot(color: accent, label: "Most")
                legendDot(color: AppTheme.mint, label: "Kész")
                legendDot(color: AppTheme.ink.opacity(0.25), label: "Zárva")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .softCard()
    }

    private var levelsList: some View {
        VStack(spacing: 12) {
            ForEach(LearningLevel.all) { level in
                levelRow(level)
            }
        }
    }

    @ViewBuilder
    private func levelRow(_ level: LearningLevel) -> some View {
        let status = path.status(for: level)

        switch status {
        case .locked:
            lockedLevelCard(level)
        case .current, .completed:
            NavigationLink {
                GameView(
                    profile: profile,
                    configuration: .progressive(operation: operation, level: level),
                    difficultyTier: path.difficultyTier(for: level)
                )
            } label: {
                unlockedLevelCard(level, status: status)
            }
            .buttonStyle(.plain)
        }
    }

    private func unlockedLevelCard(_ level: LearningLevel, status: LevelStatus) -> some View {
        let wins = path.masteryWins(for: level)
        let isCurrent = status == .current

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((isCurrent ? accent : AppTheme.mint).opacity(0.14))
                    .frame(width: 56, height: 56)
                if status == .completed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppTheme.mint)
                } else {
                    Text("\(level.number)")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .foregroundStyle(accent)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(level.title(for: operation))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text(status == .completed ? "Újra játszhatod gyakorláshoz" : masteryCaption(wins: wins))
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 4) {
                Text(level.shortLabel(for: operation))
                    .font(.system(.title3, design: .rounded, weight: .heavy))
                    .foregroundStyle(isCurrent ? accent : AppTheme.mint)
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isCurrent ? accent : AppTheme.mint)
            }
        }
        .padding(15)
        .softCard()
        .overlay {
            if isCurrent {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(accent.opacity(0.45), lineWidth: 2)
            }
        }
    }

    private func lockedLevelCard(_ level: LearningLevel) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.ink.opacity(0.06))
                    .frame(width: 56, height: 56)
                Image(systemName: "lock.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.ink.opacity(0.28))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(level.title(for: operation))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink.opacity(0.45))
                Text("Még zárva — előbb ügyeskedj az előző szinten")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(level.shortLabel(for: operation))
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(AppTheme.ink.opacity(0.22))
        }
        .padding(15)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityLabel("\(level.title(for: operation)), zárva")
    }

    private func masteryCaption(wins: Int) -> String {
        let remaining = max(0, LearningRules.masteryRoundsRequired - wins)
        if wins == 0 {
            return "2 ügyes kör kell a következő szinthez"
        }
        if remaining == 0 {
            return "Szuper! Ez a szint megvan"
        }
        return "Még \(remaining) ügyes kör a következő szinthez"
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .bold))
                .foregroundStyle(.secondary)
        }
    }
}
