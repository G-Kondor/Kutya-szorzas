import SwiftUI

struct DogCollectionView: View {
    @EnvironmentObject private var store: AppStore
    let profile: PlayerProfile

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private var owned: Set<Int> {
        Set(store.progress(for: profile).collectedDogIDs)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Text("\(owned.count) / \(DogCatalog.count) kutyus már a tiéd")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.lavender)
                        .padding(.top, 4)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<DogCatalog.count, id: \.self) { dogID in
                            dogCard(dogID)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Kutyáim")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func dogCard(_ dogID: Int) -> some View {
        VStack(spacing: 8) {
            if owned.contains(dogID) {
                DogPortrait(id: dogID)
                    .frame(height: 145)
                Text(DogCatalog.name(for: dogID))
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.ink)
            } else {
                ZStack {
                    Circle()
                        .fill(AppTheme.lavender.opacity(0.08))
                        .frame(width: 100, height: 100)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 31, weight: .bold))
                        .foregroundStyle(AppTheme.lavender.opacity(0.42))
                }
                .frame(height: 145)
                Text("Még titkos")
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .softCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(owned.contains(dogID) ? DogCatalog.name(for: dogID) : "Lezárt kutyus")
    }
}
