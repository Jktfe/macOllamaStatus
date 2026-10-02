import Foundation
import Observation
import OlusageCore

@MainActor
@Observable
final class UsageStore {
    enum Status: Equatable {
        case idle, loading
        case signedOut
        case error(String)
        case ok
    }

    private(set) var usage: Usage?
    private(set) var status: Status = .idle
    private(set) var lastUpdated: Date?

    var intervalMinutes: Int = UserDefaults.standard.object(forKey: "intervalMinutes") as? Int ?? 5 {
        didSet { UserDefaults.standard.set(intervalMinutes, forKey: "intervalMinutes"); restartTimer() }
    }

    private var source: UsageSource
    private var timer: Timer?

    init(source: UsageSource? = nil) {
        self.source = source ?? ScrapeSource()
        restartTimer()
        Task { await refresh() }
    }

    func refresh() async {
        guard status != .loading else { return }
        status = .loading
        do {
            usage = try await source.fetchUsage()
            lastUpdated = Date()
            status = .ok
        } catch ParseError.signedOut {
            status = .signedOut
        } catch ParseError.noUsageFound {
            status = .error("Couldn't find usage on the settings page")
        } catch {
            status = .error("\(error)")
        }
    }

    /// Swaps where usage comes from (scrape <-> API key) and refreshes straight away.
    func use(source: UsageSource) {
        self.source = source
        usage = nil
        status = .idle
        Task { await refresh() }
    }

    func signOut() async {
        await LoginWindowController.signOut()
        usage = nil
        status = .signedOut
    }

    private func restartTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(intervalMinutes * 60), repeats: true) { [weak self] _ in
            Task { @MainActor in await self?.refresh() }
        }
    }

    /// Short text for the menu bar.
    var menuBarTitle: String {
        switch status {
        case .signedOut: return "Sign in"
        case .error: return "⚠︎"
        default:
            guard let h = usage?.headline else { return status == .loading ? "…" : "–" }
            return "\(Int(h.percent.rounded()))%"
        }
    }
}
