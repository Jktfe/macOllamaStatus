import SwiftUI
import ServiceManagement
import OlusageCore

@main
struct OlusageApp: App {
    @State private var store = UsageStore()
    @State private var login: LoginWindowController?

    var body: some Scene {
        MenuBarExtra {
            MenuContent(store: store, openLogin: openLogin)
        } label: {
            Text("🦙 \(store.menuBarTitle)")
        }
        .menuBarExtraStyle(.menu)
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
        if store.status != .signedOut {
            Button("Sign out") { Task { await store.signOut() } }
        }
        Divider()
        Button("Quit") { NSApp.terminate(nil) }.keyboardShortcut("q")
    }
}
