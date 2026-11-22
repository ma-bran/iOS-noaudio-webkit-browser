import SwiftUI
import QuickLook

struct DownloadsView: View {
    @ObservedObject var downloads: DownloadManager
    @Environment(\.dismiss) private var dismiss
    @State private var previewURL: URL?

    var body: some View {
        NavigationStack {
            List {
                if !downloads.activeNames.isEmpty {
                    Section("Lädt gerade") {
                        ForEach(downloads.activeNames, id: \.self) { name in
                            HStack {
                                ProgressView()
                                Text(name)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                Section("Gespeichert") {
                    if downloads.files.isEmpty {
                        Text("Noch keine Downloads")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(downloads.files, id: \.self) { url in
                        HStack {
                            Button {
                                previewURL = url
                            } label: {
                                Text(url.lastPathComponent)
                                    .lineLimit(2)
                            }
                            Spacer()
                            ShareLink(item: url) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                    .onDelete { offsets in
                        let urls = offsets.map { downloads.files[$0] }
                        for url in urls {
                            downloads.delete(url)
                        }
                    }
                }
            }
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
            .quickLookPreview($previewURL)
            .onAppear {
                downloads.refresh()
            }
        }
    }
}
