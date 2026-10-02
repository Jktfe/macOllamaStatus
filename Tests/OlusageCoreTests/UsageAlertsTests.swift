import XCTest
@testable import OlusageCore

final class UsageAlertsTests: XCTestCase {
    private func usage(_ p: Double) -> Usage { Usage(meters: [UsageMeter(label: "Weekly", percent: p, resetText: nil)]) }

    func testFirstReadNeverAlerts() {
        XCTAssertTrue(UsageAlerts.newAlerts(previous: nil, current: usage(95)).isEmpty)
    }

    func testCrossingAlertsOnce() {
        let a = UsageAlerts.newAlerts(previous: ["Weekly": 70], current: usage(76))
        XCTAssertEqual(a, [UsageAlert(label: "Weekly", threshold: 75, percent: 76)])
        XCTAssertTrue(UsageAlerts.newAlerts(previous: ["Weekly": 76], current: usage(80)).isEmpty)
    }

    func testJumpGivesHighestThresholdOnly() {
        XCTAssertEqual(UsageAlerts.newAlerts(previous: ["Weekly": 50], current: usage(95)).map(\.threshold), [90])
    }

    func testResetRearms() {
        XCTAssertEqual(UsageAlerts.newAlerts(previous: ["Weekly": 5], current: usage(80)).map(\.threshold), [75])
    }
}
