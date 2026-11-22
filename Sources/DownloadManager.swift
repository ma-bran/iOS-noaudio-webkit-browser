import SwiftUI
import WebKit
import UniformTypeIdentifiers

/// Lädt Dateien in den App-Ordner Documents/Downloads.
/// Erlaubt sind nur Dokument- und Bildtypen (Config.allowedDownloadExtensions). Alles andere,
/// auch ZIP-Archive, wird abgelehnt, sonst ließe sich die Ton-Sperre über Downloads umgehen.
final class DownloadManager: NSObject, ObservableObject, WKDownloadDelegate {
    @Published var activeNames: [String] = []
    @Published var message: String?
    @Published private(set) var files: [URL] = []

    private var destinations: [ObjectIdentifier: URL] = [:]

    static var directory: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Downloads", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    override init() {
        super.init()
        refresh()
    }

    func refresh() {
        let urls = (try? FileManager.default.contentsOfDirectory(
            at: Self.directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        files = urls.sorted { a, b in
            let da = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            let db = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
            return da > db
        }
    }

    func delete(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
        refresh()
    }

    static func safeName(_ suggested: String) -> String {
        let last = (suggested as NSString).lastPathComponent
        let trimmed = last.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "download" : trimmed
    }

    static func uniqueURL(for name: String) -> URL {
        let dir = directory
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var candidate = dir.appendingPathComponent(name)
        var n = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            let newName = ext.isEmpty ? "\(base) (\(n))" : "\(base) (\(n)).\(ext)"
            candidate = dir.appendingPathComponent(newName)
            n += 1
        }
        return candidate
    }

    // MARK: WKDownloadDelegate

    func download(_ download: WKDownload,
                  decideDestinationUsing response: URLResponse,
                  suggestedFilename: String,
                  completionHandler: @escaping (URL?) -> Void) {
        var name = Self.safeName(suggestedFilename)
        var ext = (name as NSString).pathExtension.lowercased()
        let mime = response.mimeType?.lowercased() ?? ""

        // Fehlt die Endung, aus dem Dateityp ableiten
        if ext.isEmpty, let guessed = UTType(mimeType: mime)?.preferredFilenameExtension {
            ext = guessed.lowercased()
            name += "." + ext
        }

        let isMedia = mime.hasPrefix("audio/") || mime.hasPrefix("video/")
        if isMedia || !Config.allowedDownloadExtensions.contains(ext) {
            DispatchQueue.main.async {
                self.message = "Dieser Dateityp ist gesperrt. Erlaubt sind nur Dokumente und Bilder (keine Archive, Audio oder Video)."
            }
            completionHandler(nil)
            return
        }

        let destination = Self.uniqueURL(for: name)
        destinations[ObjectIdentifier(download)] = destination
        DispatchQueue.main.async {
            self.activeNames.append(destination.lastPathComponent)
        }
        completionHandler(destination)
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let url = destinations.removeValue(forKey: ObjectIdentifier(download)) else { return }
        DispatchQueue.main.async {
            self.activeNames.removeAll { $0 == url.lastPathComponent }
            self.refresh()
            self.message = "Gespeichert: \(url.lastPathComponent)"
        }
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        // Ohne Ziel wurde der Download schon vorher abgelehnt (Meldung ist gesetzt).
        guard let url = destinations.removeValue(forKey: ObjectIdentifier(download)) else { return }
        try? FileManager.default.removeItem(at: url)
        DispatchQueue.main.async {
            self.activeNames.removeAll { $0 == url.lastPathComponent }
            self.message = "Download fehlgeschlagen: \(url.lastPathComponent)"
        }
    }
}
