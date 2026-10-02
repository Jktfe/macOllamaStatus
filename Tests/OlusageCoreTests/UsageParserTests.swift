import XCTest
@testable import OlusageCore

final class UsageParserTests: XCTestCase {
    func testParsesLabelAndPercentOnSameLine() throws {
        let text = """
        Plan
        Weekly usage 12% used
        Resets in 4 days
        Session usage 42% used
        Resets in 3 hours
        """
        let usage = try UsageParser.parse(text: text)
        XCTAssertEqual(usage.meters.count, 2)
        XCTAssertEqual(usage.meters[0], UsageMeter(label: "Weekly usage", percent: 12, resetText: "Resets in 4 days"))
        XCTAssertEqual(usage.headline?.label, "Session usage")
    }

    func testParsesLabelOnPreviousLine() throws {
        let usage = try UsageParser.parse(text: "Session\n7.5%\nResets in 1 hour")
        XCTAssertEqual(usage.meters.first, UsageMeter(label: "Session", percent: 7.5, resetText: "Resets in 1 hour"))
    }

    func testSignedOutPage() {
        XCTAssertThrowsError(try UsageParser.parse(text: "Sign in to Ollama\nEmail")) {
            XCTAssertEqual($0 as? ParseError, .signedOut)
        }
    }

    func testNoUsageFound() {
        XCTAssertThrowsError(try UsageParser.parse(text: "Account\nSign out\nProfile")) {
            XCTAssertEqual($0 as? ParseError, .noUsageFound)
        }
    }
}
