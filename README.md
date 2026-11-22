# Ruhe-Browser

Minimaler iPhone-Browser ohne Ton. Alle Webseiten sind erreichbar, Audio ist gesperrt.

## Was die App kann

- Adressleiste mit Suche (DuckDuckGo), Zurück, Vor, Neu laden, Startseite
- **Tabs** (höchstens 5, einstellbar in `Sources/Config.swift`). Links mit target=_blank öffnen einen neuen Tab.
- **Downloads**: Dateien landen im App-Ordner (Menü unten rechts, "Downloads"). Dort kannst du sie ansehen, teilen und löschen. Erlaubt sind nur Dokumente und Bilder (Liste in `Config.swift`). Archive wie ZIP sowie Audio und Video werden abgelehnt, sonst ließe sich die Ton-Sperre umgehen.
- **Lesezeichen** (höchstens 5): Im Menü unten rechts "Lesezeichen setzen". Sie erscheinen auf der Startseite eines neuen Tabs, zum Löschen lange drücken.
- Keine Sprünge in andere Apps, Mikrofon und Kamera werden immer abgelehnt
- Kein Ton über mehrere Schichten (siehe `Sources/AudioBlocker.swift`)

## Einstellungen

In `Sources/Config.swift`:

- `blockAllMedia = true`: Audio und Video werden gar nicht erst geladen (stärkste Sperre).
- `blockAllMedia = false`: Videos dürfen stumm laufen.
- `searchURL`: Suchmaschine.
- `maxTabs` und `maxBookmarks`: Obergrenzen.
- `allowedDownloadExtensions`: erlaubte Dateitypen für Downloads.

## IPA bauen (ohne Mac)

1. Auf GitHub ein Repository anlegen (öffentlich: kostenlose Build-Minuten; privat: begrenzte Freiminuten).
2. Den **Inhalt** des Projektordners hochladen, auch den Ordner `.github`. Bei einem Update die neuen Dateien aus `Sources` und `project.yml` hochladen, Dateien mit gleichem Namen werden überschrieben.
3. Tab "Actions" → "Build IPA" → "Run workflow".
4. Wenn der Lauf grün ist: im Lauf unter "Artifacts" `NoAudioBrowser-ipa` herunterladen und entpacken. Darin liegt `NoAudioBrowser.ipa`.
5. Die IPA in AltStore installieren.

Schlägt der Build fehl, den Fehlertext aus dem Lauf kopieren und weitergeben.

## Wichtig für Profil und Allowlist

- AltStore signiert die App mit deiner Apple-ID und ändert dabei die Bundle-ID. Für die Allowlist in `ablenkungsfrei.mobileconfig` brauchst du die **tatsächliche** Bundle-ID der installierten App.
- Mit kostenloser Apple-ID läuft die App nach 7 Tagen ab und muss über AltStore erneuert werden.
- In der Profil-Datei sind `allowEnterpriseAppTrust` und `allowAppInstallation` auf `false`. Das kann AltStore blockieren. Vorher testen.
- Die Dateien-App ist in der Allowlist nicht enthalten. Heruntergeladene Dateien öffnest du deshalb über die Downloads-Liste in der App.
