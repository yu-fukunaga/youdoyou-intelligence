import Foundation
import Testing

@testable import AppCore

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0) -> Date {
  Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

@MainActor
struct ReportViewModel_DateIntervalTests {

  nonisolated static let cases:
    [(
      periodType: PeriodType,
      currentDate: Date,
      expected: DateInterval
    )] = [
      (
        periodType: .day,
        currentDate: date(2026, 1, 1),
        expected: DateInterval(
          start: Calendar.current.startOfDay(for: date(2026, 1, 1)),
          duration: 86400
        )
      ),
      (
        periodType: .week,
        currentDate: date(2026, 1, 1),
        expected: DateInterval(
          start: date(2025, 12, 29),
          end: date(2026, 1, 5)
        )
      ),
      (
        periodType: .quarter,
        currentDate: date(2026, 1, 1),
        expected: DateInterval(
          start: date(2025, 10, 13),  // 12週前の月曜
          end: date(2026, 1, 5)  // 今週の翌月曜
        )
      ),
      (
        periodType: .year,
        currentDate: date(2026, 1, 1),
        expected: DateInterval(
          start: date(2026, 1, 1),
          end: date(2027, 1, 1)
        )
      ),
    ]

  @Test(arguments: cases)
  func dateInterval(
    periodType: PeriodType,
    currentDate: Date,
    expected: DateInterval
  ) {
    let vm = ReportViewModel(repository: MockActivityRepository())
    vm.periodType = periodType
    vm.currentDate = currentDate

    #expect(vm.dateInterval == expected)
  }

}

@MainActor
struct ReportViewModel_DateRangeTextTests {

  nonisolated static let cases:
    [(
      periodType: PeriodType,
      currentDate: Date,
      expected: String
    )] = [
      (
        periodType: .day,
        currentDate: date(2026, 1, 1),
        expected: "2026/01/01",
      ),
      (
        periodType: .week,
        currentDate: date(2026, 1, 1),
        expected: "2025/12/29 - 2026/01/04"
      ),
      (
        periodType: .quarter,
        currentDate: date(2026, 1, 1),
        expected: "2025/10/13 - 2026/01/04",
      ),
      (
        periodType: .year,
        currentDate: date(2026, 1, 1),
        expected: "2026年"
      ),
    ]

  @Test(arguments: cases)
  func dateRangeText_test(
    periodType: PeriodType,
    currentDate: Date,
    expected: String
  ) {
    let vm = ReportViewModel(repository: MockActivityRepository())
    vm.periodType = periodType
    vm.currentDate = currentDate

    #expect(vm.dateRangeText == expected)
  }

}

@MainActor
struct ReportViewModel_BucketsTests {

  nonisolated static let cases:
    [(
      periodType: PeriodType,
      currentDate: Date,
      expected: [DateInterval]
    )] = [
      (
        periodType: .day,
        currentDate: date(2026, 1, 1),
        expected: [
          DateInterval(start: date(2026, 1, 1, 0), end: date(2026, 1, 1, 1)),
          DateInterval(start: date(2026, 1, 1, 1), end: date(2026, 1, 1, 2)),
          DateInterval(start: date(2026, 1, 1, 2), end: date(2026, 1, 1, 3)),
          DateInterval(start: date(2026, 1, 1, 3), end: date(2026, 1, 1, 4)),
          DateInterval(start: date(2026, 1, 1, 4), end: date(2026, 1, 1, 5)),
          DateInterval(start: date(2026, 1, 1, 5), end: date(2026, 1, 1, 6)),
          DateInterval(start: date(2026, 1, 1, 6), end: date(2026, 1, 1, 7)),
          DateInterval(start: date(2026, 1, 1, 7), end: date(2026, 1, 1, 8)),
          DateInterval(start: date(2026, 1, 1, 8), end: date(2026, 1, 1, 9)),
          DateInterval(start: date(2026, 1, 1, 9), end: date(2026, 1, 1, 10)),
          DateInterval(start: date(2026, 1, 1, 10), end: date(2026, 1, 1, 11)),
          DateInterval(start: date(2026, 1, 1, 11), end: date(2026, 1, 1, 12)),
          DateInterval(start: date(2026, 1, 1, 12), end: date(2026, 1, 1, 13)),
          DateInterval(start: date(2026, 1, 1, 13), end: date(2026, 1, 1, 14)),
          DateInterval(start: date(2026, 1, 1, 14), end: date(2026, 1, 1, 15)),
          DateInterval(start: date(2026, 1, 1, 15), end: date(2026, 1, 1, 16)),
          DateInterval(start: date(2026, 1, 1, 16), end: date(2026, 1, 1, 17)),
          DateInterval(start: date(2026, 1, 1, 17), end: date(2026, 1, 1, 18)),
          DateInterval(start: date(2026, 1, 1, 18), end: date(2026, 1, 1, 19)),
          DateInterval(start: date(2026, 1, 1, 19), end: date(2026, 1, 1, 20)),
          DateInterval(start: date(2026, 1, 1, 20), end: date(2026, 1, 1, 21)),
          DateInterval(start: date(2026, 1, 1, 21), end: date(2026, 1, 1, 22)),
          DateInterval(start: date(2026, 1, 1, 22), end: date(2026, 1, 1, 23)),
          DateInterval(start: date(2026, 1, 1, 23), end: date(2026, 1, 1, 24)),
        ]
      ),
      (
        periodType: .week,
        currentDate: date(2026, 1, 1),
        expected: [
          DateInterval(start: date(2025, 12, 29), end: date(2025, 12, 30)),
          DateInterval(start: date(2025, 12, 30), end: date(2025, 12, 31)),
          DateInterval(start: date(2025, 12, 31), end: date(2026, 1, 1)),
          DateInterval(start: date(2026, 1, 1), end: date(2026, 1, 2)),
          DateInterval(start: date(2026, 1, 2), end: date(2026, 1, 3)),
          DateInterval(start: date(2026, 1, 3), end: date(2026, 1, 4)),
          DateInterval(start: date(2026, 1, 4), end: date(2026, 1, 5)),
        ]
      ),
      (
        periodType: .quarter,
        currentDate: date(2026, 1, 1),
        expected: [
          DateInterval(start: date(2025, 10, 13), end: date(2025, 10, 20)),
          DateInterval(start: date(2025, 10, 20), end: date(2025, 10, 27)),
          DateInterval(start: date(2025, 10, 27), end: date(2025, 11, 3)),
          DateInterval(start: date(2025, 11, 3), end: date(2025, 11, 10)),
          DateInterval(start: date(2025, 11, 10), end: date(2025, 11, 17)),
          DateInterval(start: date(2025, 11, 17), end: date(2025, 11, 24)),
          DateInterval(start: date(2025, 11, 24), end: date(2025, 12, 1)),
          DateInterval(start: date(2025, 12, 1), end: date(2025, 12, 8)),
          DateInterval(start: date(2025, 12, 8), end: date(2025, 12, 15)),
          DateInterval(start: date(2025, 12, 15), end: date(2025, 12, 22)),
          DateInterval(start: date(2025, 12, 22), end: date(2025, 12, 29)),
          DateInterval(start: date(2025, 12, 29), end: date(2026, 1, 5)),
        ]
      ),
      (
        periodType: .year,
        currentDate: date(2026, 1, 1),
        expected: [
          DateInterval(start: date(2026, 1, 1), end: date(2026, 2, 1)),
          DateInterval(start: date(2026, 2, 1), end: date(2026, 3, 1)),
          DateInterval(start: date(2026, 3, 1), end: date(2026, 4, 1)),
          DateInterval(start: date(2026, 4, 1), end: date(2026, 5, 1)),
          DateInterval(start: date(2026, 5, 1), end: date(2026, 6, 1)),
          DateInterval(start: date(2026, 6, 1), end: date(2026, 7, 1)),
          DateInterval(start: date(2026, 7, 1), end: date(2026, 8, 1)),
          DateInterval(start: date(2026, 8, 1), end: date(2026, 9, 1)),
          DateInterval(start: date(2026, 9, 1), end: date(2026, 10, 1)),
          DateInterval(start: date(2026, 10, 1), end: date(2026, 11, 1)),
          DateInterval(start: date(2026, 11, 1), end: date(2026, 12, 1)),
          DateInterval(start: date(2026, 12, 1), end: date(2027, 1, 1)),
        ]
      ),
    ]

  @Test(arguments: cases)
  func dateRangeText_test(
    periodType: PeriodType,
    currentDate: Date,
    expected: [DateInterval]
  ) {
    let vm = ReportViewModel(repository: MockActivityRepository())
    vm.periodType = periodType
    vm.currentDate = currentDate

    #expect(vm.buckets == expected)
  }

}
