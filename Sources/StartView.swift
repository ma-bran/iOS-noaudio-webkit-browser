import SwiftUI

/// Startseite eines neuen Tabs: nur die Lesezeichen (höchstens 5), sonst nichts.
struct StartView: View {
    @ObservedObject var bookmarks: BookmarkStore
    let open: (Bookmark) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "speaker.slash.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)

                Text("Ruhe-Browser")
                    .font(.title2.bold())

                if bookmarks.items.isEmpty {
                    Text("Noch keine Lesezeichen. Öffne eine Seite und wähle im Menü unten rechts \"Lesezeichen setzen\". Es sind höchstens \(Config.maxBookmarks) möglich.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(bookmarks.items) { bookmark in
                        Button {
                            open(bookmark)
                        } label: {
                            HStack {
                                Text(bookmark.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                Spacer()
                                Text(bookmark.host)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                bookmarks.remove(bookmark)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                    Text("Zum Löschen ein Lesezeichen lange drücken.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
