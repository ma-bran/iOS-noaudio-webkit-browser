import Foundation

enum Config {
    /// true:  Audio und Video werden gar nicht erst geladen (stärkste Sperre, auch keine stummen Videos).
    /// false: Videos dürfen laufen, aber komplett stumm (Ton wird per Skript erzwungen ausgeschaltet).
    static let blockAllMedia = true

    /// Startseite
    static let homeURL = URL(string: "https://duckduckgo.com")!

    /// Suchmaschine für Eingaben, die keine Adresse sind
    static let searchURL = "https://duckduckgo.com/?q="
}
