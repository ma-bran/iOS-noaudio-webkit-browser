import SwiftUI
import WebKit

/// Hält alle Tabs, die Lesezeichen und die Downloads.
/// Der erste Tab wird erst angelegt, wenn die Audio-Sperren aktiv sind.
final class BrowserStore: ObservableObject {
    @Published private(set) var tabs: [TabModel] = []
    @Published var selectedID: UUID?

    /// Wird von allen Tabs geteilt, damit Skript und Inhaltsregel überall greifen.
    let controller = WKUserContentController()
    let bookmarks = BookmarkStore()
    let downloads = DownloadManager()

    var currentTab: TabModel? {
        tabs.first { $0.id == selectedID }
    }

    init() {
        AudioBlocker.install(in: controller) { [weak self] in
            self?.newTab()
        }
    }

    func newTab(url: URL? = nil) {
        guard tabs.count < Config.maxTabs else { return }
        let tab = TabModel(store: self, initialURL: url)
        tabs.append(tab)
        selectedID = tab.id
    }

    func select(_ tab: TabModel) {
        selectedID = tab.id
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
    }

    /// Links mit target=_blank: neuer Tab, wenn noch Platz ist, sonst im selben Tab.
    func open(_ url: URL, from tab: TabModel) {
        if tabs.count < Config.maxTabs {
            newTab(url: url)
        } else {
            tab.load(url)
        }
    }
}
