import Foundation

enum Config {
    /// true:  Audio und Video werden gar nicht erst geladen (stärkste Sperre, auch keine stummen Videos).
    /// false: Videos dürfen laufen, aber komplett stumm (Ton wird per Skript erzwungen ausgeschaltet).
    static let blockAllMedia = true

    /// Suchmaschine für Eingaben, die keine Adresse sind
    static let searchURL = "https://duckduckgo.com/?q="

    /// Höchstzahl gleichzeitig offener Tabs
    static let maxTabs = 5

    /// Höchstzahl Lesezeichen
    static let maxBookmarks = 5

    /// Nur diese Dateitypen dürfen heruntergeladen werden. Archive (zip, rar, 7z ...) fehlen
    /// absichtlich, denn darin könnten Audio- und Videodateien stecken.
    static let allowedDownloadExtensions: Set<String> = [
        "pdf", "txt", "rtf", "csv",
        "doc", "docx", "xls", "xlsx", "ppt", "pptx", "odt", "ods", "odp",
        "pages", "numbers", "key",
        "jpg", "jpeg", "png", "gif", "heic", "webp", "tif", "tiff", "bmp"
    ]
}
