import SwiftUI
import UIKit

enum AppTheme {
    static let pink = Color(red: 0.95, green: 0.39, blue: 0.58)
    static let lavender = Color(red: 0.60, green: 0.42, blue: 0.86)
    static let peach = Color(red: 1.00, green: 0.70, blue: 0.55)
    static let mint = Color(red: 0.44, green: 0.77, blue: 0.68)
    static let ink = Color(red: 0.20, green: 0.15, blue: 0.25)
    static let background = LinearGradient(
        colors: [
            Color(red: 1.00, green: 0.94, blue: 0.96),
            Color(red: 0.95, green: 0.93, blue: 1.00),
            Color(red: 1.00, green: 0.97, blue: 0.91)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct SoftCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.9), lineWidth: 1)
            }
            .shadow(color: AppTheme.lavender.opacity(0.13), radius: 18, y: 8)
    }
}

extension View {
    func softCard() -> some View {
        modifier(SoftCardModifier())
    }
}

struct DogPortrait: View {
    let id: Int

    var body: some View {
        Group {
            if let image = DogImageLoader.image(for: id) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "pawprint.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(20)
                    .foregroundStyle(AppTheme.pink)
            }
        }
        .accessibilityLabel(L10n.dogPortraitAccessibility(DogCatalog.name(for: id)))
    }
}

enum DogImageLoader {
    static func image(for id: Int) -> UIImage? {
        let name = DogCatalog.imageName(for: id)
        if let image = UIImage(named: name) {
            return image
        }

        let subdirectories = ["Dogs", "Resources/Dogs"]
        for subdirectory in subdirectories {
            if
                let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: subdirectory),
                let image = UIImage(contentsOfFile: url.path)
            {
                return image
            }
        }
        return nil
    }
}

struct PawBadge: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .softCard()
    }
}
