import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if isShowingSplash {
                SplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            } else if let profile = store.selectedProfile {
                NavigationStack {
                    HomeView(profile: profile)
                }
                .transition(.opacity)
            } else {
                ProfilePickerView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .tint(AppTheme.pink)
        .task {
            guard isShowingSplash else { return }
            try? await Task.sleep(for: .seconds(1.35))
            withAnimation(.easeInOut(duration: 0.45)) {
                isShowingSplash = false
            }
        }
    }
}

private struct SplashView: View {
    @State private var isPulsing = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.86))
                    .frame(width: 150, height: 150)
                    .shadow(color: AppTheme.pink.opacity(0.18), radius: 24, y: 10)

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(AppTheme.pink)
                    .scaleEffect(isPulsing ? 1.06 : 0.94)
            }

            Text("Kutyaszorzás")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text("Matekozz • Gyűjts • Játssz")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(AppTheme.lavender)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ProfilePickerView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "pawprint.circle.fill")
                        .font(.system(size: 58))
                        .foregroundStyle(AppTheme.pink)
                    Text("Ki játszik most?")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Text("Válaszd ki a profilodat!")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 6)

                ForEach(PlayerProfile.all) { profile in
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            store.selectedProfile = profile
                        }
                    } label: {
                        HStack(spacing: 18) {
                            ZStack {
                                Circle()
                                    .fill(profile.tint.opacity(0.13))
                                    .frame(width: 76, height: 76)
                                Image(systemName: profile.symbol)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(profile.tint)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(profile.name)
                                    .font(.system(.title2, design: .rounded, weight: .bold))
                                    .foregroundStyle(AppTheme.ink)
                                let dogCount = store.progress(for: profile).collectedDogIDs.count
                                Text("\(dogCount) megszerzett kutyus")
                                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title2)
                                .foregroundStyle(profile.tint)
                        }
                        .padding(18)
                        .softCard()
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Megnyitja \(profile.name) játékát")
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 56)
            .padding(.bottom, 30)
        }
    }
}
