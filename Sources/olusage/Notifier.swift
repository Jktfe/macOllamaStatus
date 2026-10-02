import Foundation
import OlusageCore
import UserNotifications

/// Posts "you're nearly out" notifications. Needs the signed .app bundle; from `swift run` there is
/// no bundle, so it quietly does nothing.
enum Notifier {
    static func post(_ alert: UsageAlert) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = alert.threshold >= 100 ? "Ollama \(alert.label.lowercased()) limit reached"
                                                   : "Ollama \(alert.label.lowercased()) at \(alert.threshold)%"
            content.body = "\(Int(alert.percent.rounded()))% used."
            center.add(UNNotificationRequest(identifier: "olusage-\(alert.label)-\(alert.threshold)",
                                             content: content, trigger: nil))
        }
    }
}
