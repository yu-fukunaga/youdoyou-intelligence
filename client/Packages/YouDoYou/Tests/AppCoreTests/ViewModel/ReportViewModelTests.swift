import Domain
import Foundation
import SwiftUI
import Testing

@testable import Presentation

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0) -> Date {
  Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

private func workLog(
  workTopicId: String,
  startedAt: Date,
  endedAt: Date
) -> WorkLog {
  WorkLog(
    workTopicId: workTopicId,
    content: "",
    startedAt: startedAt,
    endedAt: endedAt,
    userId: "u1",
    userName: "user",
    userIcon: ""
  )
}

private func workTopic(id: String, title: String) -> WorkTopic {
  WorkTopic(id: id, title: title)
}

struct ReportViewModel_DateIntervalTests {

  static let cases:
    [(
      periodType: PeriodType,
      currentDate: Date,
      expected: DateInterval
    )] = [
      (
        periodType: .day,
        currentDate: date(2026, 1, 1),
        expected: DateInterval(
          start: date(2025, 12, 29),
          end: date(2026, 1, 5)
        )
      ),
      (
        periodType: .month,
        currentDate: date(2026, 1, 1),
        expected: DateInterval(
          start: date(2026, 1, 1),
          end: date(2026, 7, 1)
        )
      ),
      (
        periodType: .month,
        currentDate: date(2026, 8, 15),
        expected: DateInterval(
          start: date(2026, 7, 1),
          end: date(2027, 1, 1)
        )
      ),
      (
        periodType: .year,
        currentDate: date(2026, 1, 1),
        expected: DateInterval(
          start: date(2022, 1, 1),
          end: date(2027, 1, 1)
        )
      ),
    ]

  @Test(arguments: cases)
  @MainActor
  func dateInterval(
    periodType: PeriodType,
    currentDate: Date,
    expected: DateInterval
  ) {
    let vm = ReportViewModel(repository: MockWorkLogRepository())
    vm.periodType = periodType
    vm.currentDate = currentDate

    #expect(vm.dateInterval == expected)
  }

}

struct ReportViewModel_HeaderDateRangeTextTests {

  static let cases:
    [(
      periodType: PeriodType,
      currentDate: Date,
      expected: String
    )] = [
      (
        periodType: .day,
        currentDate: date(2026, 1, 1),
        expected: "2025年12月29日~1月4日"
      ),
      (
        periodType: .month,
        currentDate: date(2026, 1, 1),
        expected: "2026年前期",
      ),
      (
        periodType: .month,
        currentDate: date(2026, 8, 15),
        expected: "2026年後期",
      ),
      (
        periodType: .year,
        currentDate: date(2026, 1, 1),
        expected: "2022年~2026年"
      ),
    ]

  @Test(arguments: cases)
  @MainActor
  func headerDateRangeText_test(
    periodType: PeriodType,
    currentDate: Date,
    expected: String
  ) {
    let vm = ReportViewModel(repository: MockWorkLogRepository())
    vm.periodType = periodType
    vm.currentDate = currentDate

    #expect(vm.headerDateRangeText == expected)
  }

}

struct ReportViewModel_BucketsTests {

  static let cases:
    [(
      periodType: PeriodType,
      currentDate: Date,
      expected: [DateInterval]
    )] = [
      (
        periodType: .day,
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
        periodType: .month,
        currentDate: date(2026, 1, 1),
        expected: [
          DateInterval(start: date(2026, 1, 1), end: date(2026, 2, 1)),
          DateInterval(start: date(2026, 2, 1), end: date(2026, 3, 1)),
          DateInterval(start: date(2026, 3, 1), end: date(2026, 4, 1)),
          DateInterval(start: date(2026, 4, 1), end: date(2026, 5, 1)),
          DateInterval(start: date(2026, 5, 1), end: date(2026, 6, 1)),
          DateInterval(start: date(2026, 6, 1), end: date(2026, 7, 1)),
        ]
      ),
      (
        periodType: .year,
        currentDate: date(2026, 1, 1),
        expected: [
          DateInterval(start: date(2022, 1, 1), end: date(2023, 1, 1)),
          DateInterval(start: date(2023, 1, 1), end: date(2024, 1, 1)),
          DateInterval(start: date(2024, 1, 1), end: date(2025, 1, 1)),
          DateInterval(start: date(2025, 1, 1), end: date(2026, 1, 1)),
          DateInterval(start: date(2026, 1, 1), end: date(2027, 1, 1)),
        ]
      ),
    ]

  @Test(arguments: cases)
  @MainActor
  func buckets_test(
    periodType: PeriodType,
    currentDate: Date,
    expected: [DateInterval]
  ) {
    let vm = ReportViewModel(repository: MockWorkLogRepository())
    vm.periodType = periodType
    vm.currentDate = currentDate

    #expect(vm.buckets == expected)
  }

}

struct ReportViewModel_BucketLabelTests {

  static let cases:
    [(
      periodType: PeriodType,
      bucketStart: Date,
      expected: String
    )] = [
      (
        periodType: .day,
        bucketStart: date(2026, 1, 1),  // Thursday
        expected: "木"
      ),
      (
        periodType: .month,
        bucketStart: date(2026, 1, 1),
        expected: "1月"
      ),
      (
        periodType: .year,
        bucketStart: date(2026, 1, 1),
        expected: "2026年"
      ),
    ]

  @Test(arguments: cases)
  @MainActor
  func bucketLabel_test(
    periodType: PeriodType,
    bucketStart: Date,
    expected: String
  ) {
    // shortWeekdaySymbols depends on locale, so fix it explicitly for a deterministic result
    var calendar = Calendar(identifier: .gregorian)
    calendar.locale = Locale(identifier: "en_US")
    calendar.firstWeekday = 2

    let vm = ReportViewModel(repository: MockWorkLogRepository(), calendar: calendar)
    vm.periodType = periodType

    let bucket = DateInterval(start: bucketStart, end: bucketStart)
    #expect(vm.bucketLabel(for: bucket) == expected)
  }

}

struct ReportViewModel_LoadIfNeededTests {

  private struct DummyError: Error {}

  @Test
  @MainActor
  func loadIfNeeded_test() async {
    let mock = MockWorkLogRepository()
    let vm = ReportViewModel(repository: mock)

    await vm.loadIfNeeded()
    #expect(mock.queryCallCount == 1)
  }

  @Test
  @MainActor
  func loadIfNeeded_whenQueryThrows_doesNotCacheAndRetriesNextTime() async {
    let mock = MockWorkLogRepository()
    mock.stubbedError = DummyError()
    let vm = ReportViewModel(repository: mock)

    await vm.loadIfNeeded()

    #expect(mock.queryCallCount == 1)
    #expect(vm.headerTotalDuration == 0)

    // Not cached, so calling again triggers another query
    await vm.loadIfNeeded()
    #expect(mock.queryCallCount == 2)
  }

}

struct ReportViewModel_MovePeriodTests {

  static let cases:
    [(
      periodType: PeriodType,
      offset: Int,
      expected: Date
    )] = [
      (periodType: .day, offset: 1, expected: date(2026, 1, 8)),
      (periodType: .day, offset: -1, expected: date(2025, 12, 25)),
      (periodType: .month, offset: 1, expected: date(2026, 7, 1)),  // +6 months
      (periodType: .month, offset: -1, expected: date(2025, 7, 1)),  // -6 months
      (periodType: .year, offset: 1, expected: date(2031, 1, 1)),
      (periodType: .year, offset: -1, expected: date(2021, 1, 1)),
    ]

  // TODO: This test intentionally sets `now` outside the tested date range to
  // avoid the isViewingToday guard. Add a dedicated test that verifies
  // movePeriod does nothing when today falls within the current period.
  @Test(arguments: cases)
  @MainActor
  func movePeriod_test(
    periodType: PeriodType,
    offset: Int,
    expected: Date
  ) {
    let vm = ReportViewModel(repository: MockWorkLogRepository(), now: { date(2000, 1, 1) })
    vm.periodType = periodType
    vm.currentDate = date(2026, 1, 1)

    vm.movePeriod(by: offset)

    #expect(vm.currentDate == expected)
  }

}

struct ReportViewModel_ToggleItemTests {

  static let cases:
    [(
      initialSelectedItemId: String?,
      input: String,
      expected: String?
    )] = [
      (initialSelectedItemId: nil, input: "wt1", expected: "wt1"),
      (initialSelectedItemId: "wt1", input: "wt1", expected: nil),
      (initialSelectedItemId: "wt1", input: "wt2", expected: "wt2"),
    ]

  @Test(arguments: cases)
  @MainActor
  func toggleItem_test(
    initialSelectedItemId: String?,
    input: String,
    expected: String?
  ) {
    let vm = ReportViewModel(repository: MockWorkLogRepository())
    vm.selectedItemId = initialSelectedItemId

    vm.toggleItem(input)

    #expect(vm.selectedItemId == expected)
  }

}

struct ReportViewModel_HeaderTotalDurationTests {

  struct TestCase: CustomTestStringConvertible {
    let name: String
    let workLogs: [WorkLog]
    let selectedItemId: String?
    let expected: TimeInterval

    var testDescription: String { name }
  }

  static let cases: [TestCase] = [
    TestCase(
      name: "sums all workLogs without filter",
      workLogs: [
        workLog(workTopicId: "wt1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 1)),
        workLog(workTopicId: "wt2", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
      ],
      selectedItemId: nil,
      expected: 3 * 3600
    ),
    TestCase(
      name: "filters by selected workTopic",
      workLogs: [
        workLog(workTopicId: "wt1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 1)),
        workLog(workTopicId: "wt2", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
      ],
      selectedItemId: "wt1",
      expected: 1 * 3600
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func headerTotalDuration_test(testCase: TestCase) async {
    let mock = MockWorkLogRepository()
    mock.workLogs = testCase.workLogs
    let vm = ReportViewModel(repository: mock)
    vm.selectedItemId = testCase.selectedItemId

    await vm.loadIfNeeded()

    #expect(vm.headerTotalDuration == testCase.expected)
  }

}

struct ReportViewModel_HeaderAverageDurationTests {

  @Test
  @MainActor
  func headerAverageDuration_dividesByBucketCount() async {
    let mock = MockWorkLogRepository()
    mock.workLogs = [
      workLog(workTopicId: "wt1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 14))
    ]
    let vm = ReportViewModel(repository: mock)
    vm.periodType = .day
    vm.currentDate = date(2026, 1, 1)

    await vm.loadIfNeeded()

    #expect(vm.headerAverageDuration == 2 * 3600)  // 14h / 7 buckets
  }

}

struct ReportViewModel_BarChartColumnsTests {

  struct ExpectedSegment: Equatable {
    let id: String
    let title: String
    let duration: TimeInterval
  }

  struct TestCase: CustomTestStringConvertible {
    let name: String
    let workLogs: [WorkLog]
    let targetBucketIndex: Int
    let expectedSegments: [ExpectedSegment]

    var testDescription: String { name }
  }

  static let workTopics: [WorkTopic] = [
    workTopic(id: "wt1", title: "Coding"),
    workTopic(id: "wt2", title: "Meeting"),
  ]

  // Day period starting 2026/1/1: bucket 3 is the 2026/1/1 (Thu) day bucket
  static let cases: [TestCase] = [
    TestCase(
      name: "bucket with no workLogs still includes every known group at 0 duration",
      workLogs: [],
      targetBucketIndex: 3,
      expectedSegments: [
        ExpectedSegment(id: "wt1", title: "Coding", duration: 0),
        ExpectedSegment(id: "wt2", title: "Meeting", duration: 0),
      ]
    ),
    TestCase(
      name: "groups by workTopic and sums duration within the bucket",
      workLogs: [
        workLog(workTopicId: "wt1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        workLog(workTopicId: "wt2", startedAt: date(2026, 1, 1, 5), endedAt: date(2026, 1, 1, 6)),
      ],
      targetBucketIndex: 3,
      expectedSegments: [
        ExpectedSegment(id: "wt1", title: "Coding", duration: 2 * 3600),
        ExpectedSegment(id: "wt2", title: "Meeting", duration: 1 * 3600),
      ]
    ),
    TestCase(
      name: "clamps duration to the bucket when an workLog spans two buckets",
      workLogs: [
        workLog(workTopicId: "wt1", startedAt: date(2025, 12, 31, 23), endedAt: date(2026, 1, 1, 2))
      ],
      targetBucketIndex: 3,
      expectedSegments: [
        ExpectedSegment(id: "wt1", title: "Coding", duration: 2 * 3600),
        ExpectedSegment(id: "wt2", title: "Meeting", duration: 0),
      ]
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func chartBars_test(testCase: TestCase) async {
    let mock = MockWorkLogRepository()
    mock.workLogs = testCase.workLogs
    let vm = ReportViewModel(repository: mock)
    vm.periodType = .day
    vm.currentDate = date(2026, 1, 1)

    await vm.loadIfNeeded()

    let bars = vm.barChartColumns(workTopics: Self.workTopics)
    let segments =
      bars[testCase.targetBucketIndex].segments
      .map { ExpectedSegment(id: $0.id, title: $0.title, duration: $0.duration) }
      .sorted { $0.id < $1.id }

    #expect(segments == testCase.expectedSegments.sorted { $0.id < $1.id })
  }

}

struct ReportViewModel_ListRowsTests {

  struct ExpectedRow: Equatable {
    let id: String
    let title: String
    let bucketDurations: [TimeInterval]
  }

  struct TestCase: CustomTestStringConvertible {
    let name: String
    let workLogs: [WorkLog]
    let selectedItemId: String?
    let expectedRows: [ExpectedRow]

    var testDescription: String { name }
  }

  static let workTopics: [WorkTopic] = [
    workTopic(id: "wt1", title: "Coding"),
    workTopic(id: "wt2", title: "Meeting"),
  ]

  // Day period starting 2026/1/1: bucket index 3=1/1, 4=1/2, 5=1/3
  static let cases: [TestCase] = [
    TestCase(
      name: "groups by workTopic per bucket and sorts by total descending",
      workLogs: [
        workLog(workTopicId: "wt1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        workLog(workTopicId: "wt1", startedAt: date(2026, 1, 3, 1), endedAt: date(2026, 1, 3, 2)),
        workLog(workTopicId: "wt2", startedAt: date(2026, 1, 2, 1), endedAt: date(2026, 1, 2, 2)),
      ],
      selectedItemId: nil,
      expectedRows: [
        ExpectedRow(
          id: "wt1", title: "Coding",
          bucketDurations: [0, 0, 0, 2 * 3600, 0, 1 * 3600, 0]
        ),
        ExpectedRow(
          id: "wt2", title: "Meeting",
          bucketDurations: [0, 0, 0, 0, 1 * 3600, 0, 0]
        ),
      ]
    ),
    TestCase(
      name: "keeps every row visible (with its real total) even when an item is selected",
      workLogs: [
        workLog(workTopicId: "wt1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        workLog(workTopicId: "wt2", startedAt: date(2026, 1, 2, 1), endedAt: date(2026, 1, 2, 2)),
      ],
      selectedItemId: "wt1",
      expectedRows: [
        ExpectedRow(
          id: "wt1", title: "Coding",
          bucketDurations: [0, 0, 0, 2 * 3600, 0, 0, 0]
        ),
        ExpectedRow(
          id: "wt2", title: "Meeting",
          bucketDurations: [0, 0, 0, 0, 1 * 3600, 0, 0]
        ),
      ]
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func summaryRows_test(testCase: TestCase) async {
    let mock = MockWorkLogRepository()
    mock.workLogs = testCase.workLogs
    let vm = ReportViewModel(repository: mock)
    vm.periodType = .day
    vm.currentDate = date(2026, 1, 1)
    vm.selectedItemId = testCase.selectedItemId

    await vm.loadIfNeeded()

    let rows =
      vm.listRows(workTopics: Self.workTopics)
      .map { ExpectedRow(id: $0.id, title: $0.title, bucketDurations: $0.bucketDurations) }

    #expect(rows == testCase.expectedRows)
  }

}

struct ReportViewModel_TimelineTitleTests {

  struct TestCase: CustomTestStringConvertible {
    let name: String
    let id: String
    let expected: String

    var testDescription: String { name }
  }

  static let workTopics: [WorkTopic] = [
    workTopic(id: "wt1", title: "Coding"),
    workTopic(id: "wt2", title: "Meeting"),
  ]

  static let cases: [TestCase] = [
    TestCase(
      name: "resolves workTopic title",
      id: "wt1",
      expected: "Coding"
    ),
    TestCase(
      name: "falls back to the id when no matching workTopic is found",
      id: "unknown",
      expected: "unknown"
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func timelineTitle_test(testCase: TestCase) {
    let vm = ReportViewModel(repository: MockWorkLogRepository())

    #expect(vm.timelineTitle(for: testCase.id, workTopics: Self.workTopics) == testCase.expected)
  }

}
