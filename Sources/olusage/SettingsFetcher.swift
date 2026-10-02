import Foundation
import WebKit

/// Loads https://ollama.com/settings in a hidden WKWebView that shares the default (persistent)
/// website data store with the login window, then returns the page's visible text.
@MainActor
final class SettingsFetcher: NSObject, WKNavigationDelegate {
    static let settingsURL = URL(string: "https://ollama.com/settings")!

    enum FetchError: Error { case signedOut, failed(String) }

    private static let pollInterval: TimeInterval = 0.5
    private static let maxAttempts = 20   // ~10s

    private let webView: WKWebView
    private var continuation: CheckedContinuation<String, Error>?

    override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1024, height: 768), configuration: config)
        super.init()
        webView.navigationDelegate = self
    }

    func fetchText() async throws -> String {
        // A refresh already in flight is cancelled rather than leaked.
        continuation?.resume(throwing: FetchError.failed("superseded"))
        return try await withCheckedThrowingContinuation { cont in
            continuation = cont
            webView.load(URLRequest(url: Self.settingsURL, cachePolicy: .reloadIgnoringLocalCacheData))
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let host = webView.url?.host, host == "ollama.com", webView.url?.path == "/settings" else {
            finish(.failure(FetchError.signedOut))   // bounced to the sign-in page
            return
        }
        // The meters render client-side, so poll until a percentage appears (or give up and let the
        // parser report what it found).
        readText(attempt: 0)
    }

    private func readText(attempt: Int) {
        webView.evaluateJavaScript("document.body.innerText") { [weak self] result, error in
            guard let self else { return }
            if let text = result as? String {
                if text.contains("%") || attempt >= Self.maxAttempts { self.finish(.success(text)); return }
            } else if attempt >= Self.maxAttempts {
                self.finish(.failure(FetchError.failed(error?.localizedDescription ?? "no text"))); return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.pollInterval) { [weak self] in
                self?.readText(attempt: attempt + 1)
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(.failure(FetchError.failed(error.localizedDescription)))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(.failure(FetchError.failed(error.localizedDescription)))
    }

    private func finish(_ result: Result<String, Error>) {
        guard let cont = continuation else { return }
        continuation = nil
        cont.resume(with: result)
    }
}
