import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct ContentView: View {
    @StateObject private var model = BrowserModel()
    @FocusState private var addressFocused: Bool
    @State private var input = ""

    var body: some View {
        VStack(spacing: 0) {
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
                        model.submit(input)
                        addressFocused = false
                    }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            ProgressView(value: model.progress)
                .progressViewStyle(.linear)
                .opacity(model.isLoading ? 1 : 0)

            WebViewContainer(webView: model.webView)

            Divider()

            HStack {
                Button {
                    model.webView.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .disabled(!model.canGoBack)

                Spacer()

                Button {
                    model.webView.goForward()
                } label: {
                    Image(systemName: "chevron.right")
                }
                .disabled(!model.canGoForward)

                Spacer()

                Button {
                    if model.isLoading {
                        model.webView.stopLoading()
                    } else {
                        model.webView.reload()
                    }
                } label: {
                    Image(systemName: model.isLoading ? "xmark" : "arrow.clockwise")
                }

                Spacer()

                Button {
                    model.load(Config.homeURL)
                } label: {
                    Image(systemName: "house")
                }
            }
            .font(.title3)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
        }
        .onChange(of: model.urlText) { newValue in
            if !addressFocused { input = newValue }
        }
    }
}
