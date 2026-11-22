import SwiftUI
import WebKit

/// Ein Tab: eigene WKWebView, gemeinsame Audio-Sperren über store.controller.
final class TabModel: NSObject, ObservableObject, Identifiable {
    let id = UUID()
    let webView: WKWebView
    weak var store: BrowserStore?

    @Published var urlText = ""
    @Published var title = ""
    @Published var progress: Double = 0
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var hasPage = false
    @Published var showsStartPage = true

    /// Zuletzt angeforderte Adresse, falls webView.url noch leer ist (Seite lädt noch)
    private(set) var requestedURL: URL?

    private var observers: [NSKeyValueObservation] = []

    init(store: BrowserStore, initialURL: URL? = nil) {
        let config = WKWebViewConfiguration()
        config.userContentController = store.controller
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all
        config.allowsPictureInPictureMediaPlayback = false
        config.allowsAirPlayForMediaPlayback = false
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        // Damit sich Seiten wie in Safari verhalten
        config.applicationNameForUserAgent = "Version/17.0 Mobile/15E148 Safari/604.1"

        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        self.store = store

        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        observe()

        if let url = initialURL {
            load(url)
        }
    }

    private func observe() {
        observers = [
            webView.observe(\.estimatedProgress) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.progress = wv.estimatedProgress }
            },
            webView.observe(\.isLoading) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.isLoading = wv.isLoading }
            },
            webView.observe(\.canGoBack) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.canGoBack = wv.canGoBack }
            },
            webView.observe(\.canGoForward) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.canGoForward = wv.canGoForward }
            },
            webView.observe(\.title) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.title = wv.title ?? "" }
            },
            webView.observe(\.url) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    self?.urlText = wv.url?.absoluteString ?? ""
                    self?.hasPage = (wv.url != nil)
                }
            }
        ]
    }

    func load(_ url: URL) {
        showsStartPage = false
        requestedURL = url
        webView.load(URLRequest(url: url))
    }

    func submit(_ input: String) {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        load(Self.resolve(text))
    }

    static func resolve(_ text: String) -> URL {
        if let url = URL(string: text),
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https",
           url.host != nil {
            return url
        }
        if !text.contains(" "), text.contains("."),
           let url = URL(string: "https://" + text),
           url.host != nil {
            return url
        }
        let query = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text
        return URL(string: Config.searchURL + query) ?? URL(string: "https://duckduckgo.com")!
    }
}

extension TabModel: WKNavigationDelegate, WKUIDelegate {

    // Nur normale Webadressen, keine Sprünge in andere Apps (App Store, WhatsApp, Mail ...)
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let scheme = url.scheme?.lowercased() ?? ""
        guard ["http", "https", "about", "blob", "data"].contains(scheme) else {
            decisionHandler(.cancel)
            return
        }
        if navigationAction.shouldPerformDownload {
            decisionHandler(.download)
        } else {
            decisionHandler(.allow)
        }
    }

    // Audio und Video direkt blocken, Dateien (Anhänge, nicht darstellbare Typen) herunterladen
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let mime = navigationResponse.response.mimeType?.lowercased() ?? ""
        if mime.hasPrefix("audio/") || mime.hasPrefix("video/") {
            decisionHandler(.cancel)
            return
        }

        var isAttachment = false
        if let http = navigationResponse.response as? HTTPURLResponse,
           let disposition = http.value(forHTTPHeaderField: "Content-Disposition") {
            isAttachment = disposition.lowercased().hasPrefix("attachment")
        }

        if navigationResponse.isForMainFrame && (isAttachment || !navigationResponse.canShowMIMEType) {
            decisionHandler(.download)
        } else if !navigationResponse.canShowMIMEType {
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    // Aus einer Navigation wurde ein Download: dem DownloadManager übergeben
    func webView(_ webView: WKWebView,
                 navigationAction: WKNavigationAction,
                 didBecome download: WKDownload) {
        download.delegate = store?.downloads
    }

    func webView(_ webView: WKWebView,
                 navigationResponse: WKNavigationResponse,
                 didBecome download: WKDownload) {
        download.delegate = store?.downloads
    }

    // Links mit target=_blank oder window.open: neuer Tab
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil,
           let url = navigationAction.request.url,
           let scheme = url.scheme?.lowercased(),
           scheme == "http" || scheme == "https" {
            store?.open(url, from: self)
        }
        return nil
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    // Mikrofon und Kamera immer ablehnen
    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(.deny)
    }
}
