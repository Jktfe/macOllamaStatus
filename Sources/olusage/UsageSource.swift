import Foundation
import OlusageCore

/// Where usage numbers come from. The default scrapes ollama.com/settings; other sources
/// (e.g. an API key) can be swapped in without touching the store.
@MainActor
protocol UsageSource {
    /// Throws `ParseError.signedOut` / `ParseError.noUsageFound` or a source-specific error.
    func fetchUsage() async throws -> Usage
}

/// Reads the settings page through the signed-in web view and parses its visible text.
@MainActor
final class ScrapeSource: UsageSource {
    private let fetcher = SettingsFetcher()

    func fetchUsage() async throws -> Usage {
        do {
            return try UsageParser.parse(text: try await fetcher.fetchText())
        } catch SettingsFetcher.FetchError.signedOut {
            throw ParseError.signedOut
        }
    }
}
