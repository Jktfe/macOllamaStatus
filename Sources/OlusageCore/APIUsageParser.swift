import Foundation

/// Parses the JSON from `GET https://ollama.com/api/usage` (undocumented, Bearer API key):
/// `{"limits": {"session": {"usage": n, "models": [...]}, "weekly": {"usage": n, ...}}, ...}`.
///
/// The response carries no reset times, so `resetText` is always nil.
public enum APIUsageParser {
    /// Multiplier from the API's `usage` number (a 0-1 fraction, confirmed against ollama.com/settings:
    /// API 1 == site 100%) to a percentage.
    public static let percentScale: Double = 100

    public static func parse(data: Data, percentScale: Double = percentScale) throws -> Usage {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let limits = root["limits"] as? [String: Any]
        else { throw ParseError.noUsageFound }

        let known: [(key: String, label: String)] = [("session", "Session usage"), ("weekly", "Weekly usage")]
        let meters = known.compactMap { entry -> UsageMeter? in
            guard let limit = limits[entry.key] as? [String: Any],
                  let usage = (limit["usage"] as? NSNumber)?.doubleValue else { return nil }
            return UsageMeter(label: entry.label, percent: usage * percentScale, resetText: nil)
        }
        guard !meters.isEmpty else { throw ParseError.noUsageFound }
        return Usage(meters: meters)
    }
}
