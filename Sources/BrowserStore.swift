import SwiftUI
import WebKit

/// Gespeicherter Zustand der Tabs: eine Adresse pro Tab (leer = Startseite) und der aktive Tab.
private struct SavedTabs: Codable {
    var urls: [String]
    var selected: Int
}

/// Hält alle Tabs, die Lesezeichen und die Downloads.
/// Der erste Tab wird erst angelegt, wenn die Audio-Sperren aktiv sind.
final class BrowserStore: ObservableObject {
    @Published private(set) var tabs: [TabModel] = []
    @Published var selectedID: UUID?

    /// Wird von allen Tabs geteilt, damit Skript und Inhaltsregel überall greifen.
    let controller = WKUserContentController()
    let bookmarks = BookmarkStore()
    let downloads = DownloadManager()

    private let tabsKey = "tabs.v1"
    private var isRestoring = false

    var currentTab: TabModel? {
        tabs.first { $0.id == selectedID }
    }

    init() {
        AudioBlocker.install(in: controller) { [weak self] in
            guard let self = self else { return }
            AdBlocker.install(in: self.controller) { [weak self] in
                self?.restoreTabs()
            }
        }
    }

    func newTab(url: URL? = nil) {
        guard tabs.count < Config.maxTabs else { return }
        let tab = TabModel(store: self, initialURL: url)
        tabs.append(tab)
        selectedID = tab.id
        saveState()
    }

    func select(_ tab: TabModel) {
        selectedID = tab.id
        saveState()
    }

    func close(_ tab: TabModel) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        let wasSelected = (selectedID == tab.id)
        tabs.remove(at: index)
        if tabs.isEmpty {
            newTab()
        } else if wasSelected {
            selectedID = tabs[min(index, tabs.count - 1)].id
        }
        saveState()
    }

    /// Links mit target=_blank: neuer Tab, wenn noch Platz ist, sonst im selben Tab.
    func open(_ url: URL, from tab: TabModel) {
        if tabs.count < Config.maxTabs {
            newTab(url: url)
        } else {
            tab.load(url)
        }
    }

    // MARK: Tabs speichern und wiederherstellen

    /// Speichert Adressen und aktiven Tab. Wird bei jeder Änderung und beim Verlassen der App aufgerufen.
    func saveState() {
        guard !isRestoring, !tabs.isEmpty else { return }

        let urls = tabs.map { tab -> String in
            if tab.showsStartPage { return "" }
            if let current = tab.webView.url { return current.absoluteString }
            return tab.requestedURL?.absoluteString ?? ""
        }
        let index = tabs.firstIndex { $0.id == selectedID } ?? 0
        let state = SavedTabs(urls: urls, selected: index)

        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: tabsKey)
        }
    }

    private func restoreTabs() {
        var saved: SavedTabs?
        if let data = UserDefaults.standard.data(forKey: tabsKey) {
            saved = try? JSONDecoder().decode(SavedTabs.self, from: data)
        }

        guard let state = saved, !state.urls.isEmpty else {
            newTab()
            return
        }

        isRestoring = true
        for urlString in state.urls.prefix(Config.maxTabs) {
            newTab(url: urlString.isEmpty ? nil : URL(string: urlString))
        }
        isRestoring = false

        if !tabs.isEmpty {
            let index = min(max(state.selected, 0), tabs.count - 1)
            selectedID = tabs[index].id
        }
        saveState()
    }
}
