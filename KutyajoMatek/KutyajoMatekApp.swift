import SwiftUI

@main
struct KutyajoMatekApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environment(\.locale, store.resolvedLocale)
                .id(store.languagePreference.rawValue)
                .preferredColorScheme(.light)
        }
    }
}
