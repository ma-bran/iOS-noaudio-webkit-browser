# Mute-Browser

Minimaler iPhone-Browser ohne Ton. Alle Webseiten sind erreichbar, Audio ist gesperrt.

## Was die App kann

- Adressleiste mit Suche (DuckDuckGo), Zurück, Vor, Neu laden, Startseite
- Keine Tabs, keine Downloads, keine Sprünge in andere Apps
- Mikrofon und Kamera werden immer abgelehnt
- Kein Ton über mehrere Schichten (siehe `Sources/AudioBlocker.swift`)

## Einstellungen

In `Sources/Config.swift`:

- `blockAllMedia = true`: Audio und Video werden gar nicht erst geladen (stärkste Sperre).
- `blockAllMedia = false`: Videos dürfen stumm laufen.
- `homeURL` und `searchURL`: Startseite und Suchmaschine.

## IPA bauen (ohne Mac)

1. ZIP entpacken. Auf GitHub ein neues Repository anlegen (öffentlich: kostenlose Build-Minuten; privat: begrenzte Freiminuten).
2. Im Repository "Add file" → "Upload files" und den **Inhalt** des entpackten Ordners hineinziehen, auch den Ordner `.github`.
3. Tab "Actions" → "Build IPA" → "Run workflow".
4. Wenn der Lauf grün ist: im Lauf unter "Artifacts" `NoAudioBrowser-ipa` herunterladen und die ZIP-Datei entpacken. Darin liegt `NoAudioBrowser.ipa`.
5. Die IPA in AltStore installieren (auf dem iPhone über "Meine Apps" → "+", oder per AltServer am PC).

Schlägt der Build fehl, den Fehlertext aus dem Lauf kopieren und weitergeben.

## Wichtig für Profil und Allowlist

- AltStore signiert die App mit deiner Apple-ID und ändert dabei die Bundle-ID (es wird deine Team-ID angehängt). Für die Allowlist in `ablenkungsfrei.mobileconfig` brauchst du die **tatsächliche** Bundle-ID der installierten App.
- Mit kostenloser Apple-ID läuft die App nach 7 Tagen ab und muss über AltStore erneuert werden.
- In der Profil-Datei sind `allowEnterpriseAppTrust` und `allowAppInstallation` auf `false`. Das kann AltStore blockieren. Vorher testen.
