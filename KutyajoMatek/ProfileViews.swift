import PhotosUI
import SwiftUI
import UIKit

struct ProfileAvatarView: View {
    let profile: PlayerProfile
    var size: CGFloat = 76

    var body: some View {
        ZStack {
            Circle()
                .fill(profile.tint.opacity(0.14))
                .frame(width: size, height: size)

            if let image = ProfileAvatarStore.loadImage(fileName: profile.avatarFileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: profile.symbol)
                    .font(.system(size: size * 0.38, weight: .bold))
                    .foregroundStyle(profile.tint)
            }
        }
        .overlay {
            Circle()
                .stroke(.white.opacity(0.85), lineWidth: 2)
        }
        .accessibilityLabel("\(profile.name) profilképe")
    }
}

struct ProfilePickerView: View {
    @EnvironmentObject private var store: AppStore
    @State private var isCreatingProfile = false
    @State private var isShowingParents = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header

                ForEach(store.profiles) { profile in
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                            store.selectProfile(profile)
                        }
                    } label: {
                        profileRow(profile)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Megnyitja \(profile.name) játékát")
                }

                Button {
                    isCreatingProfile = true
                } label: {
                    Label("Új profil", systemImage: "plus.circle.fill")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .foregroundStyle(.white)
                        .background(AppTheme.mint, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    isShowingParents = true
                } label: {
                    Label("Szülőknek", systemImage: "lock.shield.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(AppTheme.lavender)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.top, 56)
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $isCreatingProfile) {
            NavigationStack {
                CreateProfileView(onFinished: { isCreatingProfile = false })
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isShowingParents) {
            NavigationStack {
                ParentSectionView()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "pawprint.circle.fill")
                .font(.system(size: 58))
                .foregroundStyle(AppTheme.pink)
            Text("Ki játszik most?")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(AppTheme.ink)
            Text("Válassz profilt, vagy hozz létre egy újat.")
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 6)
    }

    private func profileRow(_ profile: PlayerProfile) -> some View {
        HStack(spacing: 18) {
            ProfileAvatarView(profile: profile, size: 76)

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
}

struct CreateProfileView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var onFinished: (() -> Void)?
    var isFirstLaunch: Bool = false

    @State private var name = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    Text(isFirstLaunch ? "Hogy hívnak?" : "Új játékos")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(isFirstLaunch
                         ? "Írd be a keresztneved vagy beceneved, és már játszhatsz is. Nem kell e-mail."
                         : "Adj meg egy nevet. A kutyusok és a haladás külön mentődnek.")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    avatarPicker

                    TextField("Pl. Izabella", text: $name)
                        .textInputAutocapitalization(.words)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .padding(16)
                        .softCard()

                    Button {
                        save()
                    } label: {
                        Label(isFirstLaunch ? "Kezdhetjük!" : "Profil létrehozása", systemImage: "play.fill")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .foregroundStyle(.white)
                            .background(canSave ? AppTheme.pink : AppTheme.pink.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                }
                .padding(22)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isFirstLaunch {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Mégse") { dismiss() }
                }
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            Task {
                previewImage = await loadImage(from: newItem)
            }
        }
    }

    private var avatarPicker: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.lavender.opacity(0.14))
                    .frame(width: 120, height: 120)

                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(AppTheme.lavender)
                }
            }

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text(previewImage == nil ? "Kép választása" : "Másik kép")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.lavender)
            }

            if previewImage != nil {
                Button("Kép eltávolítása") {
                    previewImage = nil
                    pickerItem = nil
                }
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .softCard()
    }

    private func save() {
        _ = store.createProfile(name: name, avatarImage: previewImage)
        onFinished?()
        if !isFirstLaunch {
            dismiss()
        }
    }

    private func loadImage(from item: PhotosPickerItem?) async -> UIImage? {
        guard
            let item,
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
        else { return nil }
        return image
    }
}

struct EditProfileView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    let profileID: String

    @State private var name = ""
    @State private var pickerItem: PhotosPickerItem?
    @State private var previewImage: UIImage?
    @State private var removeAvatar = false
    @State private var didPickNewImage = false

    private var profile: PlayerProfile? {
        store.profile(id: profileID)
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if let profile {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Profil szerkesztése")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(AppTheme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        avatarSection(profile)

                        TextField("Név", text: $name)
                            .textInputAutocapitalization(.words)
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .padding(16)
                            .softCard()

                        Button {
                            save(profile)
                        } label: {
                            Text("Mentés")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 54)
                                .foregroundStyle(.white)
                                .background(AppTheme.pink, in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(22)
                }
                .onAppear {
                    name = profile.name
                    previewImage = ProfileAvatarStore.loadImage(fileName: profile.avatarFileName)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Mégse") { dismiss() }
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            Task {
                if let image = await loadImage(from: newItem) {
                    previewImage = image
                    removeAvatar = false
                    didPickNewImage = true
                }
            }
        }
    }

    private func avatarSection(_ profile: PlayerProfile) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(profile.tint.opacity(0.14))
                    .frame(width: 120, height: 120)

                if let previewImage, !removeAvatar {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Image(systemName: profile.symbol)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(profile.tint)
                }
            }

            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text("Kép csere")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(AppTheme.lavender)
            }

            if (previewImage != nil && !removeAvatar) || profile.avatarFileName != nil {
                Button("Kép eltávolítása") {
                    previewImage = nil
                    pickerItem = nil
                    removeAvatar = true
                    didPickNewImage = false
                }
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .softCard()
    }

    private func save(_ profile: PlayerProfile) {
        store.renameProfile(id: profile.id, to: name)
        if removeAvatar {
            store.setAvatar(for: profile.id, image: nil)
        } else if didPickNewImage, let previewImage {
            store.setAvatar(for: profile.id, image: previewImage)
        }
        dismiss()
    }

    private func loadImage(from item: PhotosPickerItem?) async -> UIImage? {
        guard
            let item,
            let data = try? await item.loadTransferable(type: Data.self),
            let image = UIImage(data: data)
        else { return nil }
        return image
    }
}
