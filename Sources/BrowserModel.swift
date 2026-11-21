import SwiftUI
import WebKit

final class BrowserModel: NSObject, ObservableObject {
    let webView: WKWebView

    @Published var urlText = ""
    @Published var progress: Double = 0
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false

    private var observers: [NSKeyValueObservation] = []
    private var ready = false
    private var pendingURL: URL?

    override init() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = .all
        config.allowsPictureInPictureMediaPlayback = false
        config.allowsAirPlayForMediaPlayback = false
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        // Damit sich Seiten wie in Safari verhalten
        config.applicationNameForUserAgent = "Version/17.0 Mobile/15E148 Safari/604.1"

        webView = WKWebView(frame: .zero, configuration: config)
        super.init()

        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        webView.uiDelegate = self
        observe()

        // Die Startseite wird erst geladen, wenn die Audio-Sperren aktiv sind.
        AudioBlocker.install(in: webView.configuration.userContentController) { [weak self] in
            guard let self = self else { return }
            self.ready = true
            self.load(self.pendingURL ?? Config.homeURL)
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
            webView.observe(\.url) { [weak self] wv, _ in
                DispatchQueue.main.async {
                    if let url = wv.url { self?.urlText = url.absoluteString }
                }
            }
        ]
    }

    func load(_ url: URL) {
        guard ready else {
            pendingURL = url
            return
        }
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
        return URL(string: Config.searchURL + query) ?? Config.homeURL
    }
}

extension BrowserModel: WKNavigationDelegate, WKUIDelegate {

    // Nur normale Webadressen, keine Sprünge in andere Apps (App Store, WhatsApp, Mail ...)
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        let scheme = url.scheme?.lowercased() ?? ""
        if ["http", "https", "about", "blob", "data"].contains(scheme) {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }

    // Keine Downloads und keine direkten Audio-/Video-Dateien
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationResponse: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let mime = navigationResponse.response.mimeType?.lowercased() ?? ""
        if mime.hasPrefix("audio/") || mime.hasPrefix("video/") || !navigationResponse.canShowMIMEType {
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    // Neue Fenster (target=_blank) im selben Fenster öffnen, keine Tabs
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
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
