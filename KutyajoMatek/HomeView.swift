import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    let profile: PlayerProfile

    private var progress: PlayerProgress {
        store.progress(for: profile)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    welcomeCard
                    statsRow
                    gameModes
                    collectionPreview
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 36)
            }
        }
        .navigationTitle("Szia, \(profile.name)!")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Profilváltás", systemImage: "person.2.fill") {
                    withAnimation(.easeInOut) {
                        store.selectedProfile = nil
                    }
                }
                .labelStyle(.iconOnly)
                .accessibilityHint("Visszalép a profilválasztóhoz")
            }
        }
    }

    private var welcomeCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(profile.tint.opacity(0.12))
                    .frame(width: 108, height: 108)

                if let dogID = progress.collectedDogIDs.last {
                    DogPortrait(id: dogID)
                        .frame(width: 92, height: 92)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(profile.tint)
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(progress.collectedDogIDs.isEmpty ? "Szerezd meg az első kutyusod!" : "Ügyesen gyűjtöd a kutyusokat!")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Text("Oldj meg 5 feladatot hibátlanul egy új barátért.")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .softCard()
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            PawBadge(
                value: "\(progress.collectedDogIDs.count)",
                label: "Kutyáim",
                color: AppTheme.pink
            )
            PawBadge(
                value: "\(progress.totalCorrectAnswers)",
                label: "Jó válasz",
                color: AppTheme.mint
            )
            PawBadge(
                value: "\(progress.failedRounds)/3",
                label: "Hibás kör",
                color: AppTheme.lavender
            )
        }
    }

    private var gameModes: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Válassz játékot")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)

            ForEach(GameMode.allCases) { mode in
                NavigationLink {
                    destination(for: mode)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: mode.symbol)
                            .font(.system(size: 24, weight: .bold))
                            .frame(width: 52, height: 52)
                            .background(modeColor(mode).opacity(0.14), in: Circle())
                            .foregroundStyle(modeColor(mode))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(mode.title)
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(AppTheme.ink)
                            Text(modeSubtitle(for: mode))
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer()
                        Image(systemName: mode == .mixed ? "play.circle.fill" : "chevron.right.circle.fill")
                            .font(.title)
                            .foregroundStyle(modeColor(mode))
                    }
                    .padding(15)
                    .softCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func destination(for mode: GameMode) -> some View {
        if let operation = mode.progressiveOperation {
            LevelSelectView(profile: profile, operation: operation)
        } else {
            GameView(profile: profile, configuration: .mixed)
        }
    }

    private func modeSubtitle(for mode: GameMode) -> String {
        guard let operation = mode.progressiveOperation else {
            return mode.subtitle
        }
        let path = store.learningPath(for: profile, operation: operation)
        let level = LearningLevel(number: path.unlockedLevel)
        return "\(mode.subtitle) · Most: \(level.shortLabel(for: operation))"
    }

    private var collectionPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Kutyáim")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
                Spacer()
                NavigationLink("Mind a 40") {
                    DogCollectionView(profile: profile)
                }
                .font(.system(.subheadline, design: .rounded, weight: .bold))
            }

            if progress.collectedDogIDs.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "lock.open.fill")
                        .font(.title2)
                        .foregroundStyle(AppTheme.peach)
                    Text("A hibátlan kör után itt jelenik meg az első kutyusod.")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .softCard()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(progress.collectedDogIDs.suffix(6).reversed(), id: \.self) { id in
                            VStack(spacing: 4) {
                                DogPortrait(id: id)
                                    .frame(width: 90, height: 90)
                                    .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 20))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                Text(DogCatalog.name(for: id))
                                    .font(.system(.caption, design: .rounded, weight: .semibold))
                                    .foregroundStyle(AppTheme.ink)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func modeColor(_ mode: GameMode) -> Color {
        switch mode {
        case .multiplication: AppTheme.pink
        case .division: AppTheme.lavender
        case .mixed: AppTheme.mint
        }
    }
}
