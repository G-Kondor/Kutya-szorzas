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
                    HomeView(profileID: profile.id)
                }
                .transition(.opacity)
            } else if store.hasProfiles {
                ProfilePickerView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                CreateProfileView(isFirstLaunch: true)
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

            Text("Kutyajo matek")
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
