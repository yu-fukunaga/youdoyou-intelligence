import Foundation
import SwiftUI
import Testing

@testable import AppCore

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0) -> Date {
  Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

private func workLog(
  domainId: String,
  topicId: String,
  startedAt: Date,
  endedAt: Date
) -> WorkLog {
  WorkLog(
    domainId: domainId,
    topicId: topicId,
    content: "",
    startedAt: startedAt,
    endedAt: endedAt,
    userId: "u1",
    userName: "user",
    userIcon: ""
  )
}

private func domain(id: String, title: String, topics: [Topic] = []) -> Domain {
  var d = Domain(title: title, description: "", topics: topics)
  d.id = id
  return d
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
        expected: "Thu"
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

  @Test(arguments: cases)
  @MainActor
  func movePeriod_test(
    periodType: PeriodType,
    offset: Int,
    expected: Date
  ) {
    let vm = ReportViewModel(repository: MockWorkLogRepository())
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
      (initialSelectedItemId: nil, input: "d1", expected: "d1"),
      (initialSelectedItemId: "d1", input: "d1", expected: nil),
      (initialSelectedItemId: "d1", input: "d2", expected: "d2"),
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

struct ReportViewModel_GroupingUnitTests {

  @Test
  @MainActor
  func changingGroupingUnit_resetsSelectedItem() {
    let vm = ReportViewModel(repository: MockWorkLogRepository())
    vm.selectedItemId = "d1"

    vm.groupingUnit = .topic

    #expect(vm.selectedItemId == nil)
  }

}

struct ReportViewModel_HeaderTotalDurationTests {

  struct TestCase: CustomTestStringConvertible {
    let name: String
    let workLogs: [WorkLog]
    let groupingUnit: GroupingUnit
    let selectedItemId: String?
    let expected: TimeInterval

    var testDescription: String { name }
  }

  static let cases: [TestCase] = [
    TestCase(
      name: "sums all workLogs without filter",
      workLogs: [
        workLog(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 1)),
        workLog(domainId: "d2", topicId: "t2", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
      ],
      groupingUnit: .domain,
      selectedItemId: nil,
      expected: 3 * 3600
    ),
    TestCase(
      name: "filters by selected domain",
      workLogs: [
        workLog(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 1)),
        workLog(domainId: "d2", topicId: "t2", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
      ],
      groupingUnit: .domain,
      selectedItemId: "d1",
      expected: 1 * 3600
    ),
    TestCase(
      name: "filters by selected topic",
      workLogs: [
        workLog(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 1)),
        workLog(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
      ],
      groupingUnit: .topic,
      selectedItemId: "t2",
      expected: 2 * 3600
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func headerTotalDuration_test(testCase: TestCase) async {
    let mock = MockWorkLogRepository()
    mock.workLogs = testCase.workLogs
    let vm = ReportViewModel(repository: mock)
    vm.groupingUnit = testCase.groupingUnit
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
      workLog(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 14))
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
    let domains: [Domain]
    let groupingUnit: GroupingUnit
    let targetBucketIndex: Int
    let expectedSegments: [ExpectedSegment]

    var testDescription: String { name }
  }

  static let domains: [Domain] = [
    domain(id: "d1", title: "Work", topics: [Topic(id: "t1", title: "Coding"), Topic(id: "t2", title: "Meeting")]),
    domain(id: "d2", title: "Life", topics: []),
  ]

  // Day period starting 2026/1/1: bucket 3 is the 2026/1/1 (Thu) day bucket
  static let cases: [TestCase] = [
    TestCase(
      name: "bucket with no workLogs still includes every known group at 0 duration",
      workLogs: [],
      domains: domains,
      groupingUnit: .domain,
      targetBucketIndex: 3,
      expectedSegments: [
        ExpectedSegment(id: "d1", title: "Work", duration: 0),
        ExpectedSegment(id: "d2", title: "Life", duration: 0),
      ]
    ),
    TestCase(
      name: "groups by domain and sums duration within the bucket",
      workLogs: [
        workLog(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        workLog(domainId: "d2", topicId: "t9", startedAt: date(2026, 1, 1, 5), endedAt: date(2026, 1, 1, 6)),
      ],
      domains: domains,
      groupingUnit: .domain,
      targetBucketIndex: 3,
      expectedSegments: [
        ExpectedSegment(id: "d1", title: "Work", duration: 2 * 3600),
        ExpectedSegment(id: "d2", title: "Life", duration: 1 * 3600),
      ]
    ),
    TestCase(
      name: "groups by topic when grouping unit is topic",
      workLogs: [
        workLog(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        workLog(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 1, 5), endedAt: date(2026, 1, 1, 6)),
      ],
      domains: domains,
      groupingUnit: .topic,
      targetBucketIndex: 3,
      expectedSegments: [
        ExpectedSegment(id: "t1", title: "Coding", duration: 2 * 3600),
        ExpectedSegment(id: "t2", title: "Meeting", duration: 1 * 3600),
      ]
    ),
    TestCase(
      name: "clamps duration to the bucket when an workLog spans two buckets",
      workLogs: [
        workLog(domainId: "d1", topicId: "t1", startedAt: date(2025, 12, 31, 23), endedAt: date(2026, 1, 1, 2))
      ],
      domains: domains,
      groupingUnit: .domain,
      targetBucketIndex: 3,
      expectedSegments: [
        ExpectedSegment(id: "d1", title: "Work", duration: 2 * 3600),
        ExpectedSegment(id: "d2", title: "Life", duration: 0),
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
    vm.groupingUnit = testCase.groupingUnit

    await vm.loadIfNeeded()

    let bars = vm.barChartColumns(domains: testCase.domains)
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
    let domains: [Domain]
    let groupingUnit: GroupingUnit
    let selectedItemId: String?
    let expectedRows: [ExpectedRow]

    var testDescription: String { name }
  }

  static let domains: [Domain] = [
    domain(id: "d1", title: "Work", topics: [Topic(id: "t1", title: "Coding"), Topic(id: "t2", title: "Meeting")]),
    domain(id: "d2", title: "Life", topics: []),
  ]

  // Day period starting 2026/1/1: bucket index 3=1/1, 4=1/2, 5=1/3
  static let cases: [TestCase] = [
    TestCase(
      name: "groups by domain per bucket and sorts by total descending",
      workLogs: [
        workLog(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        workLog(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 3, 1), endedAt: date(2026, 1, 3, 2)),
        workLog(domainId: "d2", topicId: "t9", startedAt: date(2026, 1, 2, 1), endedAt: date(2026, 1, 2, 2)),
      ],
      domains: domains,
      groupingUnit: .domain,
      selectedItemId: nil,
      expectedRows: [
        ExpectedRow(
          id: "d1", title: "Work",
          bucketDurations: [0, 0, 0, 2 * 3600, 0, 1 * 3600, 0]
        ),
        ExpectedRow(
          id: "d2", title: "Life",
          bucketDurations: [0, 0, 0, 0, 1 * 3600, 0, 0]
        ),
      ]
    ),
    TestCase(
      name: "groups by topic when grouping unit is topic",
      workLogs: [
        workLog(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        workLog(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 2, 1), endedAt: date(2026, 1, 2, 2)),
      ],
      domains: domains,
      groupingUnit: .topic,
      selectedItemId: nil,
      expectedRows: [
        ExpectedRow(
          id: "t1", title: "Coding",
          bucketDurations: [0, 0, 0, 2 * 3600, 0, 0, 0]
        ),
        ExpectedRow(
          id: "t2", title: "Meeting",
          bucketDurations: [0, 0, 0, 0, 1 * 3600, 0, 0]
        ),
      ]
    ),
    TestCase(
      name: "keeps every row visible (with its real total) even when an item is selected",
      workLogs: [
        workLog(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        workLog(domainId: "d2", topicId: "t9", startedAt: date(2026, 1, 2, 1), endedAt: date(2026, 1, 2, 2)),
      ],
      domains: domains,
      groupingUnit: .domain,
      selectedItemId: "d1",
      expectedRows: [
        ExpectedRow(
          id: "d1", title: "Work",
          bucketDurations: [0, 0, 0, 2 * 3600, 0, 0, 0]
        ),
        ExpectedRow(
          id: "d2", title: "Life",
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
    vm.groupingUnit = testCase.groupingUnit
    vm.selectedItemId = testCase.selectedItemId

    await vm.loadIfNeeded()

    let rows =
      vm.listRows(domains: testCase.domains)
      .map { ExpectedRow(id: $0.id, title: $0.title, bucketDurations: $0.bucketDurations) }

    #expect(rows == testCase.expectedRows)
  }

}

struct ReportViewModel_TimelineTitleTests {

  struct TestCase: CustomTestStringConvertible {
    let name: String
    let groupingUnit: GroupingUnit
    let id: String
    let expected: String

    var testDescription: String { name }
  }

  static let domains: [Domain] = [
    domain(id: "d1", title: "Work", topics: [Topic(id: "t1", title: "Coding")]),
    domain(id: "d2", title: "Life", topics: []),
  ]

  static let cases: [TestCase] = [
    TestCase(
      name: "resolves domain title when grouping unit is domain",
      groupingUnit: .domain,
      id: "d1",
      expected: "Work"
    ),
    TestCase(
      name: "falls back to the id when no matching domain is found",
      groupingUnit: .domain,
      id: "unknown",
      expected: "unknown"
    ),
    TestCase(
      name: "resolves topic title by searching across all domains when grouping unit is topic",
      groupingUnit: .topic,
      id: "t1",
      expected: "Coding"
    ),
    TestCase(
      name: "falls back to the id when no domain contains a matching topic",
      groupingUnit: .topic,
      id: "unknown",
      expected: "unknown"
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func timelineTitle_test(testCase: TestCase) {
    let vm = ReportViewModel(repository: MockWorkLogRepository())
    vm.groupingUnit = testCase.groupingUnit

    #expect(vm.timelineTitle(for: testCase.id, domains: Self.domains) == testCase.expected)
  }

}
