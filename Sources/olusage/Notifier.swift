import Foundation
import UserNotifications
import OlusageCore

/// Posts a macOS notification when a usage meter crosses a warning threshold.
/// Only works from the signed .app bundle (`scripts/build-app.sh`); under `swift run` it is a no-op.
@MainActor
enum Notifier {
    private static var available: Bool { Bundle.main.bundleURL.pathExtension == "app" }

    /// Asks for permission once; macOS remembers the answer.
    static func requestAuthorization() {
        guard available else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func post(_ alerts: [UsageAlert]) {
        guard available else { return }
        for alert in alerts {
            let content = UNMutableNotificationContent()
            content.title = alert.threshold >= 100 ? "Ollama \(alert.label.lowercased()) used up"
                                                    : "Ollama \(alert.label.lowercased()) at \(alert.threshold)%"
            content.body = "You're at \(Int(alert.percent.rounded()))%. Slow down to avoid hitting the limit."
            content.sound = .default
            let request = UNNotificationRequest(identifier: "olusage.\(alert.label).\(alert.threshold)",
                                                content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request)
        }
    }
}
