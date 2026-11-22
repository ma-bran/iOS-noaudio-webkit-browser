import Foundation

struct Bookmark: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var url: String

    var host: String {
        URL(string: url)?.host ?? url
    }
}

/// Höchstens Config.maxBookmarks Lesezeichen, gespeichert in den App-Einstellungen.
final class BookmarkStore: ObservableObject {
    @Published private(set) var items: [Bookmark] = []
    private let key = "bookmarks.v1"

    init() {
        load()
    }

    var isFull: Bool {
        items.count >= Config.maxBookmarks
    }

    func contains(_ url: String) -> Bool {
        items.contains { $0.url == url }
    }

    @discardableResult
    func add(title: String, url: String) -> Bool {
        guard !isFull, !contains(url) else { return false }
        items.append(Bookmark(title: title, url: url))
        save()
        return true
    }

    func remove(_ bookmark: Bookmark) {
        items.removeAll { $0.id == bookmark.id }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) else { return }
        items = Array(decoded.prefix(Config.maxBookmarks))
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
