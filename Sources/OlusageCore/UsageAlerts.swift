import Foundation

/// Decides when to warn that a meter has crossed a usage threshold. Pure logic so it is testable;
/// the app layer turns the result into a notification.
public struct UsageAlert: Equatable, Sendable {
    public let label: String
    public let threshold: Int
    public let percent: Double
}

public enum UsageAlerts {
    public static let defaultThresholds = [75, 90, 100]

    /// Alerts for thresholds newly crossed since `previous` (per-meter percent by label, nil on first
    /// read). The first read only seeds state, so launching the app at 95% doesn't nag; a meter that
    /// drops (usage reset) re-arms its thresholds.
    public static func newAlerts(previous: [String: Double]?, current: Usage,
                                 thresholds: [Int] = defaultThresholds) -> [UsageAlert] {
        guard let previous else { return [] }
        return current.meters.flatMap { meter -> [UsageAlert] in
            let before = previous[meter.label] ?? 0
            // Highest threshold crossed wins, so jumping 50% -> 95% gives one alert, not two.
            guard let crossed = thresholds.sorted().last(where: { Double($0) <= meter.percent && Double($0) > before })
            else { return [] }
            return [UsageAlert(label: meter.label, threshold: crossed, percent: meter.percent)]
        }
    }
}
