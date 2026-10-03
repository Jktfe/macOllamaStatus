import SwiftUI
import ServiceManagement
import OlusageCore

@main
struct OlusageApp: App {
    @State private var store = UsageStore(source: KeyStore.load().map { HybridSource(apiKey: $0) })
    @State private var login: LoginWindowController?

    var body: some Scene {
        MenuBarExtra {
            MenuContent(store: store, openLogin: openLogin, promptForKey: promptForKey)
        } label: {
            let high = (store.usage?.headline?.percent ?? 0) >= 90
            HStack(spacing: 3) {
                Image(nsImage: MenuBarIcon.llama)
                Text("\(high ? "⚠︎ " : "")\(store.menuBarTitle)")
            }
        }
        .menuBarExtraStyle(.menu)
    }

    /// Asks for an Ollama API key, stores it in the Keychain and switches to the API source.
    private func promptForKey() {
        let field = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        field.placeholderString = "Ollama API key"
        let alert = NSAlert()
        alert.messageText = "Use an Ollama API key"
        alert.informativeText = "Create one at ollama.com/settings/keys. It is stored in your Keychain. Reset times need a sign-in too (menu: Sign in for reset times)."
        alert.accessoryView = field
        alert.addButton(withTitle: "Use key")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate()
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let key = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        KeyStore.save(key)
        store.use(source: HybridSource(apiKey: key))
    }

    private func openLogin() {
        let controller = LoginWindowController { Task { await store.refresh() } }
        login = controller
        controller.show()
    }
}

struct MenuContent: View {
    let store: UsageStore
    let openLogin: () -> Void
    let promptForKey: () -> Void

    var body: some View {
        switch store.status {
        case .signedOut:
            Text("Not signed in")
            Button("Sign in…", action: openLogin)
        case .error(let message):
            Text(message)
        default:
            if let usage = store.usage {
                ForEach(Array(usage.meters.enumerated()), id: \.offset) { _, m in
                    Text("\(m.label): \(Int(m.percent.rounded()))%" + (m.resetText.map { " · \($0)" } ?? ""))
                }
            } else {
                Text("Loading…")
            }
        }
        if let updated = store.lastUpdated {
            Divider()
            Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
        }
        Divider()
        Button("Refresh now") { Task { await store.refresh() } }.keyboardShortcut("r")
        Picker("Refresh every", selection: Bindable(store).intervalMinutes) {
            ForEach([1, 5, 15], id: \.self) { Text("\($0) min").tag($0) }
        }
        Toggle("Launch at login", isOn: Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { on in try? (on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()) }
        ))
        if KeyStore.load() == nil {
            Button("Use API key…", action: promptForKey)
        } else {
            Button("Sign in for reset times…", action: openLogin)
            Button("Back to sign-in mode") { KeyStore.delete(); store.use(source: ScrapeSource()) }
        }
        if store.status != .signedOut && KeyStore.load() == nil {
            Button("Sign out") { Task { await store.signOut() } }
        }
        Divider()
        Button("Quit") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}
