import Foundation

/// One usage meter on the settings page, e.g. "Session usage 42% used, resets in 3 hours".
public struct UsageMeter: Equatable, Sendable {
    public let label: String
    public let percent: Double
    public let resetText: String?

    public init(label: String, percent: Double, resetText: String?) {
        self.label = label
        self.percent = percent
        self.resetText = resetText
    }
}

public struct Usage: Equatable, Sendable {
    public let meters: [UsageMeter]
    public init(meters: [UsageMeter]) { self.meters = meters }

    /// The most-used meter, shown in the menu bar title.
    public var headline: UsageMeter? { meters.max { $0.percent < $1.percent } }
}

public enum ParseError: Error, Equatable {
    case signedOut
    case noUsageFound
}

/// Parses the visible text (`document.body.innerText`) of https://ollama.com/settings.
///
/// ollama.com has no public usage API, so this is deliberately tolerant: it looks for lines
/// containing a percentage, takes the nearest preceding non-empty line as the label, and an
/// optional following "Resets ..." line as the reset text.
public enum UsageParser {
    public static func parse(text: String) throws -> Usage {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let lower = text.lowercased()
        if lower.contains("sign in") && !lower.contains("sign out") && !lower.contains("usage") {
            throw ParseError.signedOut
        }

        var meters: [UsageMeter] = []
        for (i, line) in lines.enumerated() {
            guard let percent = firstPercent(in: line) else { continue }
            let previous = i > 0 ? lines[i - 1] : nil
            let reset = lines[(i + 1)...].prefix(2).first { $0.lowercased().hasPrefix("reset") }
            // Skip percentages in unrelated prose ("Save 20% on annual plans").
            let context = [previous, line].compactMap { $0 }.joined(separator: " ").lowercased()
            guard reset != nil || context.contains("usage") || context.contains("used") else { continue }
            let label = labelFor(line: line, previous: previous)
            meters.append(UsageMeter(label: label, percent: percent, resetText: reset))
        }
        guard !meters.isEmpty else { throw ParseError.noUsageFound }
        return Usage(meters: meters)
    }

    private static func firstPercent(in line: String) -> Double? {
        guard let range = line.range(of: #"\d+(\.\d+)?\s*%"#, options: .regularExpression) else { return nil }
        let number = line[range].dropLast().trimmingCharacters(in: .whitespaces)
        return Double(number)
    }

    private static func labelFor(line: String, previous: String?) -> String {
        // "Weekly usage 12%" -> label is the text before the number.
        if let range = line.range(of: #"\d+(\.\d+)?\s*%"#, options: .regularExpression) {
            let before = line[..<range.lowerBound].trimmingCharacters(in: CharacterSet(charactersIn: " :-"))
            if !before.isEmpty { return before }
        }
        return previous ?? "Usage"
    }
}

extension Usage {
    /// Fills in missing reset text from `other` (typically the scraped settings page), matching meters by
    /// window: anything mentioning "session" pairs with "session", "week"/"weekly" with "week". Percentages
    /// are never taken from `other`, so a stale scrape can't override fresher API numbers.
    public func fillingResets(from other: Usage) -> Usage {
        func window(_ label: String) -> String? {
            let l = label.lowercased()
            if l.contains("session") { return "session" }
            if l.contains("week") { return "week" }
            return nil
        }
        let resets = other.meters.reduce(into: [String: String]()) { dict, m in
            if let w = window(m.label), let r = m.resetText { dict[w] = dict[w] ?? r }
        }
        return Usage(meters: meters.map { m in
            guard m.resetText == nil, let w = window(m.label), let r = resets[w] else { return m }
            return UsageMeter(label: m.label, percent: m.percent, resetText: r)
        })
    }
}
