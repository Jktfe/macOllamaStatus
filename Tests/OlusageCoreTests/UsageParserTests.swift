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

    func testIgnoresPercentagesInProse() throws {
        let text = "Session usage 10% used\nResets in 1 hour\nSave 20% on annual plans"
        let usage = try UsageParser.parse(text: text)
        XCTAssertEqual(usage.meters.map(\.label), ["Session usage"])
    }

    func testPercentWithSpaceAndDecimal() throws {
        let usage = try UsageParser.parse(text: "Weekly usage: 33.5 % used")
        XCTAssertEqual(usage.meters.first?.percent, 33.5)
        XCTAssertEqual(usage.meters.first?.label, "Weekly usage")
    }

    func testHeadlineIsHighestPercent() throws {
        let usage = try UsageParser.parse(text: "A 5% used\nB 90% used\nC 40% used")
        XCTAssertEqual(usage.headline?.label, "B")
    }

    func testNoUsageFound() {
        XCTAssertThrowsError(try UsageParser.parse(text: "Account\nSign out\nProfile")) {
            XCTAssertEqual($0 as? ParseError, .noUsageFound)
        }
    }
}

final class APIUsageParserTests: XCTestCase {
    func testParsesSessionAndWeekly() throws {
        let json = #"{"activity":{"cost":"0"},"limits":{"session":{"usage":0,"models":[]},"weekly":{"usage":12.5,"models":[{"name":"m","request_count":3}]}}}"#
        let usage = try APIUsageParser.parse(data: Data(json.utf8), percentScale: 1)
        XCTAssertEqual(usage.meters, [
            UsageMeter(label: "Session usage", percent: 0, resetText: nil),
            UsageMeter(label: "Weekly usage", percent: 12.5, resetText: nil),
        ])
    }

    func testScaleConvertsFraction() throws {
        let json = #"{"limits":{"weekly":{"usage":0.25}}}"#
        XCTAssertEqual(try APIUsageParser.parse(data: Data(json.utf8), percentScale: 100).meters.first?.percent, 25)
    }

    func testRejectsUnexpectedJSON() {
        XCTAssertThrowsError(try APIUsageParser.parse(data: Data("{}".utf8)))
        XCTAssertThrowsError(try APIUsageParser.parse(data: Data("nope".utf8)))
    }
}
