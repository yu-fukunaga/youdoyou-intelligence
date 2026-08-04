import Foundation
import Testing

@testable import AppCore

struct TimeIntervalReportTextTests {

  static let cases: [(TimeInterval, String)] = [
    (0.0, "0分"),
    (1.0, "0分"),
    (0.0 * 3600.0 + 1.0 * 60.0, "1分"),
    (0.0 * 3600.0 + 59.0 * 60.0, "59分"),
    (1.0 * 3600.0, "1時間"),
    (1.0 * 3600.0 + 1.0 * 60.0, "1時間1分"),
    (2.0 * 3600.0, "2時間"),
  ]
  @Test(arguments: cases)
  func reportTest(seconds: TimeInterval, expected: String) {
    #expect(seconds.reportText == expected)
  }
}
