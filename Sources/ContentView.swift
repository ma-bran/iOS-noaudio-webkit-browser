import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct ContentView: View {
    @EnvironmentObject private var store: BrowserStore

    var body: some View {
        if let tab = store.currentTab {
            BrowserPage(tab: tab, bookmarks: store.bookmarks, downloads: store.downloads)
                .id(tab.id)
        } else {
            ProgressView()
        }
    }
}

struct BrowserPage: View {
    @EnvironmentObject private var store: BrowserStore
    @ObservedObject var tab: TabModel
    @ObservedObject var bookmarks: BookmarkStore
    @ObservedObject var downloads: DownloadManager

    @FocusState private var addressFocused: Bool
    @State private var input = ""
    @State private var showTabs = false
    @State private var showDownloads = false

    private var canGoBackNow: Bool {
        tab.showsStartPage ? tab.hasPage : tab.canGoBack
    }

    private var canAddBookmark: Bool {
        !bookmarks.isFull && !tab.showsStartPage && tab.hasPage && !bookmarks.contains(tab.urlText)
    }

    private var bookmarkLabel: String {
        if bookmarks.contains(tab.urlText) && !tab.showsStartPage {
            return "Schon als Lesezeichen gespeichert"
        }
        if bookmarks.isFull {
            return "Lesezeichen voll (max. \(Config.maxBookmarks))"
        }
        return "Lesezeichen setzen"
    }

    var body: some View {
        VStack(spacing: 0) {
            addressBar

            ProgressView(value: tab.progress)
                .progressViewStyle(.linear)
                .opacity(tab.isLoading ? 1 : 0)

            ZStack {
                WebViewContainer(webView: tab.webView)
                if tab.showsStartPage {
                    StartView(bookmarks: bookmarks) { bookmark in
                        if let url = URL(string: bookmark.url) {
                            tab.load(url)
                        }
                    }
                }
            }

            Divider()

            bottomBar
        }
        .onAppear {
            input = tab.showsStartPage ? "" : tab.urlText
        }
        .onChange(of: tab.urlText) { newValue in
            if !addressFocused && !tab.showsStartPage {
                input = newValue
            }
            store.saveState()
        }
        .onChange(of: tab.showsStartPage) { isStart in
            if isStart {
                input = ""
            } else if !addressFocused {
                input = tab.urlText
            }
            store.saveState()
        }
        .sheet(isPresented: $showTabs) {
            TabSwitcherView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showDownloads) {
            DownloadsView(downloads: downloads)
        }
        .alert("Download", isPresented: Binding(
            get: { downloads.message != nil },
            set: { newValue in
                if !newValue { downloads.message = nil }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(downloads.message ?? "")
        }
    }

    private var addressBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "speaker.slash.fill")
                .foregroundStyle(.secondary)
            TextField("Suchen oder Adresse eingeben", text: $input)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.webSearch)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.go)
                .focused($addressFocused)
                .onSubmit {
                    tab.submit(input)
                    addressFocused = false
                }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var bottomBar: some View {
        HStack {
            Button {
                if tab.showsStartPage {
                    tab.showsStartPage = false
                } else {
                    tab.webView.goBack()
                }
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(!canGoBackNow)

            Spacer()

            Button {
                tab.webView.goForward()
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(tab.showsStartPage || !tab.canGoForward)

            Spacer()

            Button {
                if tab.isLoading {
                    tab.webView.stopLoading()
                } else {
                    tab.webView.reload()
                }
            } label: {
                Image(systemName: tab.isLoading ? "xmark" : "arrow.clockwise")
            }
            .disabled(tab.showsStartPage)

            Spacer()

            Button {
                tab.showsStartPage = true
            } label: {
                Image(systemName: "house")
            }

            Spacer()

            Button {
                showTabs = true
            } label: {
                Text("\(store.tabs.count)")
                    .font(.footnote.bold())
                    .frame(width: 24, height: 24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(lineWidth: 2)
                    )
            }

            Spacer()

            Menu {
                Button {
                    addBookmark()
                } label: {
                    Label(bookmarkLabel, systemImage: "star")
                }
                .disabled(!canAddBookmark)

                Button {
                    showDownloads = true
                } label: {
                    Label("Downloads", systemImage: "arrow.down.circle")
                }
            } label: {
                Image(systemName: downloads.activeNames.isEmpty ? "ellipsis.circle" : "arrow.down.circle.fill")
            }
        }
        .font(.title3)
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    private func addBookmark() {
        let host = URL(string: tab.urlText)?.host ?? tab.urlText
        let name = tab.title.isEmpty ? host : tab.title
        bookmarks.add(title: name, url: tab.urlText)
    }
}
