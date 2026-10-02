import AppKit
import WebKit

/// A plain browser window for signing in to ollama.com. Credentials are entered on ollama.com's
/// own page; we only ever see the resulting cookie, kept in WebKit's persistent store.
@MainActor
final class LoginWindowController: NSObject, WKNavigationDelegate, WKUIDelegate, NSWindowDelegate {
    private var window: NSWindow?
    private var popups: [NSWindow] = []
    private var webView: WKWebView?
    private let onSignedIn: () -> Void

    init(onSignedIn: @escaping () -> Void) { self.onSignedIn = onSignedIn }

    func show() {
        if let window { window.makeKeyAndOrderFront(nil); NSApp.activate(); return }
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = self
        web.uiDelegate = self
        let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 640),
                           styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        win.title = "Sign in to Ollama"
        win.contentView = web
        win.delegate = self
        win.isReleasedWhenClosed = false
        win.center()
        window = win; webView = web
        web.load(URLRequest(url: SettingsFetcher.settingsURL))   // redirects to sign-in, then back
        win.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url?.host == "ollama.com", webView.url?.path == "/settings" {
            window?.close()
            onSignedIn()
        }
    }

    // Sign-in providers (e.g. for 2FA) open popups with window.open(); without this they are blocked.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let popup = WKWebView(frame: .zero, configuration: configuration)
        popup.uiDelegate = self
        let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 640),
                           styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        win.contentView = popup
        win.isReleasedWhenClosed = false
        win.center()
        win.makeKeyAndOrderFront(nil)
        popups.append(win)
        return popup
    }

    func webViewDidClose(_ webView: WKWebView) {
        popups.first { $0.contentView === webView }?.close()
        popups.removeAll { $0.contentView === webView }
    }

    func windowWillClose(_ notification: Notification) {
        guard (notification.object as? NSWindow) === window else { return }
        popups.forEach { $0.close() }; popups = []
        window = nil; webView = nil
    }

    /// Removes the ollama.com cookies/storage so the next refresh reports signed-out.
    static func signOut() async {
        let store = WKWebsiteDataStore.default()
        let records = await store.dataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes())
        let relevant = records.filter { $0.displayName.contains("ollama") || $0.displayName.contains("workos") }
        await store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: relevant)
    }
}
