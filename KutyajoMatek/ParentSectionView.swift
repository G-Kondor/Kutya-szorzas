import SwiftUI

struct ParentSectionView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    @State private var isUnlocked = false
    @State private var gateAnswer = ""
    @State private var gateError = false
    @State private var profilePendingReset: PlayerProfile?
    @State private var profilePendingDelete: PlayerProfile?

    private var gateQuestion: String { L10n.text("Mennyi 7 + 5?") }
    private let gateSolution = "12"

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Szülőknek")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text("A játék, a profilok és a kutyagyűjtemény teljesen offline működik. Nincs bejelentkezés.")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)

                    if isUnlocked {
                        unlockedContent
                    } else {
                        gateCard
                    }
                }
                .padding(22)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Kész") { dismiss() }
            }
        }
        .confirmationDialog(
            resetTitle,
            isPresented: Binding(
                get: { profilePendingReset != nil },
                set: { if !$0 { profilePendingReset = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let profile = profilePendingReset {
                Button("Haladás törlése", role: .destructive) {
                    store.resetProgress(for: profile.id)
                    profilePendingReset = nil
                }
                Button("Mégse", role: .cancel) {
                    profilePendingReset = nil
                }
            }
        } message: {
            if let profile = profilePendingReset {
                Text(L10n.resetProgressMessage(profile.name))
            }
        }
        .confirmationDialog(
            deleteTitle,
            isPresented: Binding(
                get: { profilePendingDelete != nil },
                set: { if !$0 { profilePendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let profile = profilePendingDelete {
                Button("Profil törlése", role: .destructive) {
                    store.deleteProfile(id: profile.id)
                    profilePendingDelete = nil
                    if !store.hasProfiles {
                        dismiss()
                    }
                }
                Button("Mégse", role: .cancel) {
                    profilePendingDelete = nil
                }
            }
        } message: {
            if let profile = profilePendingDelete {
                Text(L10n.deleteProfileMessage(profile.name))
            }
        }
    }

    private var resetTitle: String {
        if let profile = profilePendingReset {
            return L10n.resetProgressTitle(profile.name)
        }
        return L10n.text("Haladás törlése?")
    }

    private var deleteTitle: String {
        if let profile = profilePendingDelete {
            return L10n.deleteProfileTitle(profile.name)
        }
        return L10n.text("Profil törlése?")
    }

    private var gateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Szülői kapu", systemImage: "lock.fill")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.lavender)

            Text(gateQuestion)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)

            TextField("Válasz", text: $gateAnswer)
                .keyboardType(.numberPad)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .padding(14)
                .background(.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))

            if gateError {
                Text("Ez nem stimmel. Próbáld újra!")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.pink)
            }

            Button("Belépés") {
                if gateAnswer.trimmingCharacters(in: .whitespacesAndNewlines) == gateSolution {
                    withAnimation(.easeInOut) {
                        isUnlocked = true
                        gateError = false
                    }
                } else {
                    gateError = true
                }
            }
            .font(.system(.headline, design: .rounded, weight: .bold))
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(.white)
            .background(AppTheme.lavender, in: RoundedRectangle(cornerRadius: 16))
            .buttonStyle(.plain)
        }
        .padding(18)
        .softCard()
    }

    private var unlockedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profilkezelés")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)

            Text("A „Haladás törlése” csak az eredményeket törli. A „Profil törlése” az egész profilt eltávolítja.")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)

            if store.profiles.isEmpty {
                Text("Nincs még profil. A gyerek a kezdőképernyőn tud újat létrehozni.")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(18)
                    .softCard()
            } else {
                ForEach(store.profiles) { profile in
                    parentProfileCard(profile)
                }
            }

            futureEmailNote
        }
    }

    private func parentProfileCard(_ profile: PlayerProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ProfileAvatarView(profile: profile, size: 56)
                VStack(alignment: .leading, spacing: 3) {
                    Text(profile.name)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(
                        L10n.dogsAndRounds(
                            dogs: store.progress(for: profile).collectedDogIDs.count,
                            rounds: store.progress(for: profile).completedRounds
                        )
                    )
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                profilePendingReset = profile
            } label: {
                Label("Haladás törlése", systemImage: "arrow.counterclockwise")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(AppTheme.ink)
                    .background(AppTheme.peach.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            Button {
                profilePendingDelete = profile
            } label: {
                Label("Profil törlése", systemImage: "trash.fill")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(.white)
                    .background(AppTheme.pink, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .softCard()
    }

    private var futureEmailNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Hírlevél később", systemImage: "envelope")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)
            Text("Az e-mailes feliratkozás ehhez a verzióhoz nincs bekötve. A gyerekek adatai, képei és játékhaladása nem kerül semmilyen levelezőlistára.")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .softCard()
    }
}
