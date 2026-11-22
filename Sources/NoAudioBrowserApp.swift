import SwiftUI

@main
struct NoAudioBrowserApp: App {
    @StateObject private var store = BrowserStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
