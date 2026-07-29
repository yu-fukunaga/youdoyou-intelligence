import Foundation
import SwiftUI
import Testing

@testable import AppCore

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0) -> Date {
  Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

private func activity(
  domainId: String,
  topicId: String,
  startedAt: Date,
  endedAt: Date
) -> Activity {
  Activity(
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
          start: date(2026, 1, 1),
          end: date(2026, 1, 2)
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
        periodType: .sixMonths,
        currentDate: date(2026, 1, 1),
        expected: DateInterval(
          start: date(2026, 1, 1),
          end: date(2026, 7, 1)
        )
      ),
      (
        periodType: .sixMonths,
        currentDate: date(2026, 8, 15),
        expected: DateInterval(
          start: date(2026, 7, 1),
          end: date(2027, 1, 1)
        )
      ),
      (
        periodType: .fiveYears,
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
    let vm = ReportViewModel(repository: MockActivityRepository())
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
        expected: "2026/01/01",
      ),
      (
        periodType: .week,
        currentDate: date(2026, 1, 1),
        expected: "2025年12月29日~1月4日"
      ),
      (
        periodType: .sixMonths,
        currentDate: date(2026, 1, 1),
        expected: "2026年前期",
      ),
      (
        periodType: .sixMonths,
        currentDate: date(2026, 8, 15),
        expected: "2026年後期",
      ),
      (
        periodType: .fiveYears,
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
    let vm = ReportViewModel(repository: MockActivityRepository())
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
        periodType: .sixMonths,
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
        periodType: .fiveYears,
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
    let vm = ReportViewModel(repository: MockActivityRepository())
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
        bucketStart: date(2026, 1, 1),
        expected: ""
      ),
      (
        periodType: .week,
        bucketStart: date(2026, 1, 1),  // Thursday
        expected: "Thu"
      ),
      (
        periodType: .sixMonths,
        bucketStart: date(2026, 1, 1),
        expected: "1月"
      ),
      (
        periodType: .fiveYears,
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

    let vm = ReportViewModel(repository: MockActivityRepository(), calendar: calendar)
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
    let mock = MockActivityRepository()
    let vm = ReportViewModel(repository: mock)

    await vm.loadIfNeeded()
    #expect(mock.queryCallCount == 1)
  }

  @Test
  @MainActor
  func loadIfNeeded_whenQueryThrows_doesNotCacheAndRetriesNextTime() async {
    let mock = MockActivityRepository()
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
      (periodType: .day, offset: 1, expected: date(2026, 1, 2)),
      (periodType: .day, offset: -1, expected: date(2025, 12, 31)),
      (periodType: .week, offset: 1, expected: date(2026, 1, 8)),
      (periodType: .week, offset: -1, expected: date(2025, 12, 25)),
      (periodType: .sixMonths, offset: 1, expected: date(2026, 7, 1)),  // +6 months
      (periodType: .sixMonths, offset: -1, expected: date(2025, 7, 1)),  // -6 months
      (periodType: .fiveYears, offset: 1, expected: date(2031, 1, 1)),
      (periodType: .fiveYears, offset: -1, expected: date(2021, 1, 1)),
    ]

  @Test(arguments: cases)
  @MainActor
  func movePeriod_test(
    periodType: PeriodType,
    offset: Int,
    expected: Date
  ) {
    let vm = ReportViewModel(repository: MockActivityRepository())
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
    let vm = ReportViewModel(repository: MockActivityRepository())
    vm.selectedItemId = initialSelectedItemId

    vm.toggleItem(input)

    #expect(vm.selectedItemId == expected)
  }

}

struct ReportViewModel_GroupingUnitTests {

  @Test
  @MainActor
  func changingGroupingUnit_resetsSelectedItem() {
    let vm = ReportViewModel(repository: MockActivityRepository())
    vm.selectedItemId = "d1"

    vm.groupingUnit = .topic

    #expect(vm.selectedItemId == nil)
  }

}

struct ReportViewModel_HeaderTotalDurationTests {

  struct TestCase: CustomTestStringConvertible {
    let name: String
    let activities: [Activity]
    let groupingUnit: GroupingUnit
    let selectedItemId: String?
    let expected: TimeInterval

    var testDescription: String { name }
  }

  static let cases: [TestCase] = [
    TestCase(
      name: "sums all activities without filter",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 1)),
        activity(domainId: "d2", topicId: "t2", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
      ],
      groupingUnit: .domain,
      selectedItemId: nil,
      expected: 3 * 3600
    ),
    TestCase(
      name: "filters by selected domain",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 1)),
        activity(domainId: "d2", topicId: "t2", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
      ],
      groupingUnit: .domain,
      selectedItemId: "d1",
      expected: 1 * 3600
    ),
    TestCase(
      name: "filters by selected topic",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 1)),
        activity(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
      ],
      groupingUnit: .topic,
      selectedItemId: "t2",
      expected: 2 * 3600
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func headerTotalDuration_test(testCase: TestCase) async {
    let mock = MockActivityRepository()
    mock.activities = testCase.activities
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
  func headerAverageDuration_day_equalsTotal() async {
    let mock = MockActivityRepository()
    mock.activities = [
      activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 3))
    ]
    let vm = ReportViewModel(repository: mock)
    vm.periodType = .day
    vm.currentDate = date(2026, 1, 1)

    await vm.loadIfNeeded()

    #expect(vm.headerAverageDuration == vm.headerTotalDuration)
  }

  @Test
  @MainActor
  func headerAverageDuration_week_dividesByBucketCount() async {
    let mock = MockActivityRepository()
    mock.activities = [
      activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 14))
    ]
    let vm = ReportViewModel(repository: mock)
    vm.periodType = .week
    vm.currentDate = date(2026, 1, 1)

    await vm.loadIfNeeded()

    #expect(vm.headerAverageDuration == 2 * 3600)  // 14h / 7 buckets
  }

}

struct ReportViewModel_TimelineActivitiesTests {

  @Test
  @MainActor
  func timelineActivities_test() async {
    let mock = MockActivityRepository()
    mock.activities = [
      activity(domainId: "d1", topicId: "t3", startedAt: date(2026, 1, 1, 2), endedAt: date(2026, 1, 1, 3)),
      activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 1)),
      activity(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 2)),
    ]
    let vm = ReportViewModel(repository: mock)

    await vm.loadIfNeeded()

    #expect(vm.timelineActivities.map { $0.topicId } == ["t1", "t2", "t3"])
  }

}

struct ReportViewModel_ClockSegmentsTests {

  static let domains: [Domain] = [
    domain(id: "d1", title: "Work", topics: []),
    domain(id: "d2", title: "Life", topics: []),
  ]

  @Test
  @MainActor
  func clockSegments_noActivities_isOneFullDayGap() async {
    let mock = MockActivityRepository()
    let vm = ReportViewModel(repository: mock)
    vm.periodType = .day
    vm.currentDate = date(2026, 1, 1)

    await vm.loadIfNeeded()

    let segments = vm.clockSegments(domains: Self.domains)
    #expect(segments.map(\.duration) == [86400])
  }

  @Test
  @MainActor
  func clockSegments_coversFullDayWithGapsAroundActivities() async {
    let mock = MockActivityRepository()
    mock.activities = [
      activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 10), endedAt: date(2026, 1, 1, 12))
    ]
    let vm = ReportViewModel(repository: mock)
    vm.periodType = .day
    vm.currentDate = date(2026, 1, 1)

    await vm.loadIfNeeded()

    let segments = vm.clockSegments(domains: Self.domains)
    #expect(segments.map(\.duration) == [10 * 3600, 2 * 3600, 12 * 3600])
    #expect(segments.reduce(0) { $0 + $1.duration } == 86400)
  }

  @Test
  @MainActor
  func clockSegments_clampsOverlappingActivityToStartAfterThePrevious() async {
    let mock = MockActivityRepository()
    mock.activities = [
      activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 10), endedAt: date(2026, 1, 1, 12)),
      activity(domainId: "d2", topicId: "t2", startedAt: date(2026, 1, 1, 11), endedAt: date(2026, 1, 1, 13)),
    ]
    let vm = ReportViewModel(repository: mock)
    vm.periodType = .day
    vm.currentDate = date(2026, 1, 1)

    await vm.loadIfNeeded()

    let segments = vm.clockSegments(domains: Self.domains)
    // gap(0-10), d1(10-12), d2 clamped to (12-13), gap(13-24)
    #expect(segments.map(\.duration) == [10 * 3600, 2 * 3600, 1 * 3600, 11 * 3600])
    #expect(segments.reduce(0) { $0 + $1.duration } == 86400)
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
    let activities: [Activity]
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

  // Week starting 2026/1/1: bucket 3 is the 2026/1/1 (Thu) day bucket
  static let cases: [TestCase] = [
    TestCase(
      name: "bucket with no activities gets an empty placeholder segment",
      activities: [],
      domains: domains,
      groupingUnit: .domain,
      targetBucketIndex: 3,
      expectedSegments: [ExpectedSegment(id: "empty", title: "", duration: 0)]
    ),
    TestCase(
      name: "groups by domain and sums duration within the bucket",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        activity(domainId: "d2", topicId: "t9", startedAt: date(2026, 1, 1, 5), endedAt: date(2026, 1, 1, 6)),
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
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        activity(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 1, 5), endedAt: date(2026, 1, 1, 6)),
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
      name: "clamps duration to the bucket when an activity spans two buckets",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2025, 12, 31, 23), endedAt: date(2026, 1, 1, 2))
      ],
      domains: domains,
      groupingUnit: .domain,
      targetBucketIndex: 3,
      expectedSegments: [
        ExpectedSegment(id: "d1", title: "Work", duration: 2 * 3600)
      ]
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func chartBars_test(testCase: TestCase) async {
    let mock = MockActivityRepository()
    mock.activities = testCase.activities
    let vm = ReportViewModel(repository: mock)
    vm.periodType = .week
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
    let subtitle: String?
    let bucketDurations: [TimeInterval]
  }

  struct TestCase: CustomTestStringConvertible {
    let name: String
    let activities: [Activity]
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

  // Week starting 2026/1/1: bucket index 3=1/1, 4=1/2, 5=1/3
  static let cases: [TestCase] = [
    TestCase(
      name: "groups by domain per bucket and sorts by total descending",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 3, 1), endedAt: date(2026, 1, 3, 2)),
        activity(domainId: "d2", topicId: "t9", startedAt: date(2026, 1, 2, 1), endedAt: date(2026, 1, 2, 2)),
      ],
      domains: domains,
      groupingUnit: .domain,
      selectedItemId: nil,
      expectedRows: [
        ExpectedRow(
          id: "d1", title: "Work", subtitle: nil,
          bucketDurations: [0, 0, 0, 2 * 3600, 0, 1 * 3600, 0]
        ),
        ExpectedRow(
          id: "d2", title: "Life", subtitle: nil,
          bucketDurations: [0, 0, 0, 0, 1 * 3600, 0, 0]
        ),
      ]
    ),
    TestCase(
      name: "groups by topic when grouping unit is topic",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        activity(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 2, 1), endedAt: date(2026, 1, 2, 2)),
      ],
      domains: domains,
      groupingUnit: .topic,
      selectedItemId: nil,
      expectedRows: [
        ExpectedRow(
          id: "t1", title: "Coding", subtitle: "Work",
          bucketDurations: [0, 0, 0, 2 * 3600, 0, 0, 0]
        ),
        ExpectedRow(
          id: "t2", title: "Meeting", subtitle: "Work",
          bucketDurations: [0, 0, 0, 0, 1 * 3600, 0, 0]
        ),
      ]
    ),
    TestCase(
      name: "keeps every row visible (with its real total) even when an item is selected",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        activity(domainId: "d2", topicId: "t9", startedAt: date(2026, 1, 2, 1), endedAt: date(2026, 1, 2, 2)),
      ],
      domains: domains,
      groupingUnit: .domain,
      selectedItemId: "d1",
      expectedRows: [
        ExpectedRow(
          id: "d1", title: "Work", subtitle: nil,
          bucketDurations: [0, 0, 0, 2 * 3600, 0, 0, 0]
        ),
        ExpectedRow(
          id: "d2", title: "Life", subtitle: nil,
          bucketDurations: [0, 0, 0, 0, 1 * 3600, 0, 0]
        ),
      ]
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func summaryRows_test(testCase: TestCase) async {
    let mock = MockActivityRepository()
    mock.activities = testCase.activities
    let vm = ReportViewModel(repository: mock)
    vm.periodType = .week
    vm.currentDate = date(2026, 1, 1)
    vm.groupingUnit = testCase.groupingUnit
    vm.selectedItemId = testCase.selectedItemId

    await vm.loadIfNeeded()

    let rows =
      vm.listRows(domains: testCase.domains)
      .map { ExpectedRow(id: $0.id, title: $0.title, subtitle: $0.subtitle, bucketDurations: $0.bucketDurations) }

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
    let vm = ReportViewModel(repository: MockActivityRepository())
    vm.groupingUnit = testCase.groupingUnit

    #expect(vm.timelineTitle(for: testCase.id, domains: Self.domains) == testCase.expected)
  }

}

struct ReportViewModel_TimelineColorTests {

  struct TestCase: CustomTestStringConvertible {
    let name: String
    let groupingUnit: GroupingUnit
    let activity: Activity
    let expected: Color

    var testDescription: String { name }
  }

  static let domains: [Domain] = [
    domain(id: "d1", title: "Work", topics: [Topic(id: "t1", title: "Coding"), Topic(id: "t2", title: "Meeting")]),
    domain(id: "d2", title: "Life", topics: []),
  ]

  static let cases: [TestCase] = [
    TestCase(
      name: "colors by domain index when grouping unit is domain",
      groupingUnit: .domain,
      activity: activity(domainId: "d2", topicId: "t9", startedAt: date(2026, 1, 1), endedAt: date(2026, 1, 1, 1)),
      expected: .orange
    ),
    TestCase(
      name: "colors by topic index when grouping unit is topic",
      groupingUnit: .topic,
      activity: activity(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 1), endedAt: date(2026, 1, 1, 1)),
      expected: .orange
    ),
    TestCase(
      name: "falls back to gray when the id has no color mapping",
      groupingUnit: .domain,
      activity: activity(domainId: "unknown", topicId: "t9", startedAt: date(2026, 1, 1), endedAt: date(2026, 1, 1, 1)),
      expected: .gray
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func timelineColor_test(testCase: TestCase) {
    let vm = ReportViewModel(repository: MockActivityRepository())
    vm.groupingUnit = testCase.groupingUnit

    #expect(vm.timelineColor(for: testCase.activity, domains: Self.domains) == testCase.expected)
  }

}
