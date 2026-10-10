import SwiftUI

struct LanguagePickerCard: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Nyelv / Language", systemImage: "globe")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.ink)

            Text("Alapértelmezés szerint a telefon nyelve. Itt bármikor átállíthatod.")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(AppLanguagePreference.allCases) { option in
                    languageButton(option)
                }
            }
        }
        .padding(16)
        .softCard()
    }

    private func languageButton(_ option: AppLanguagePreference) -> some View {
        let isSelected = store.languagePreference == option

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                store.setLanguagePreference(option)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isSelected ? AppTheme.mint : AppTheme.ink.opacity(0.25))

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.stableLabel)
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.ink)
                    Text(option.pickerTitle)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                (isSelected ? AppTheme.mint.opacity(0.14) : Color.white.opacity(0.55)),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(option.stableLabel)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
