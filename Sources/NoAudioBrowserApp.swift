import SwiftUI

@main
struct NoAudioBrowserApp: App {
    @StateObject private var store = BrowserStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { phase in
            // Beim Verlassen der App die offenen Tabs sichern
            if phase != .active {
                store.saveState()
            }
        }
    }
}
