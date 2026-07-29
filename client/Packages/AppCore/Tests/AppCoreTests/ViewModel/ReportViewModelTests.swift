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
        expected: "第1週 2025/12/29 - 2026/01/04"
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
        expected: "直近5年 2022 - 2026"
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

struct ReportViewModel_SelectDomainTests {

  static let cases:
    [(
      initialDomainId: String?,
      initialTopicId: String?,
      input: String?,
      expectedDomainId: String?
    )] = [
      (initialDomainId: nil, initialTopicId: nil, input: "d1", expectedDomainId: "d1"),
      (initialDomainId: "d1", initialTopicId: "t1", input: "d1", expectedDomainId: nil),
      (initialDomainId: "d1", initialTopicId: "t1", input: "d2", expectedDomainId: "d2"),
      (initialDomainId: "d1", initialTopicId: "t1", input: nil, expectedDomainId: nil),
    ]

  @Test(arguments: cases)
  @MainActor
  func selectDomain_test(
    initialDomainId: String?,
    initialTopicId: String?,
    input: String?,
    expectedDomainId: String?
  ) {
    let vm = ReportViewModel(repository: MockActivityRepository())
    vm.selectedDomainId = initialDomainId
    vm.selectedTopicId = initialTopicId

    vm.selectDomain(input)

    #expect(vm.selectedDomainId == expectedDomainId)
    #expect(vm.selectedTopicId == nil)
  }

}

struct ReportViewModel_ToggleTopicTests {

  static let cases:
    [(
      initialTopicId: String?,
      input: String,
      expected: String?
    )] = [
      (initialTopicId: nil, input: "t1", expected: "t1"),
      (initialTopicId: "t1", input: "t1", expected: nil),
      (initialTopicId: "t1", input: "t2", expected: "t2"),
    ]

  @Test(arguments: cases)
  @MainActor
  func toggleTopic_test(
    initialTopicId: String?,
    input: String,
    expected: String?
  ) {
    let vm = ReportViewModel(repository: MockActivityRepository())
    vm.selectedTopicId = initialTopicId

    vm.toggleTopic(input)

    #expect(vm.selectedTopicId == expected)
  }

}

struct ReportViewModel_HeaderTotalDurationTests {

  struct TestCase: CustomTestStringConvertible {
    let name: String
    let activities: [Activity]
    let selectedDomainId: String?
    let selectedTopicId: String?
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
      selectedDomainId: nil,
      selectedTopicId: nil,
      expected: 3 * 3600
    ),
    TestCase(
      name: "filters by domain",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 1)),
        activity(domainId: "d2", topicId: "t2", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
      ],
      selectedDomainId: "d1",
      selectedTopicId: nil,
      expected: 1 * 3600
    ),
    TestCase(
      name: "filters by domain and topic",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 1)),
        activity(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
      ],
      selectedDomainId: "d1",
      selectedTopicId: "t2",
      expected: 2 * 3600
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func headerTotalDuration_test(testCase: TestCase) async {
    let mock = MockActivityRepository()
    mock.activities = testCase.activities
    let vm = ReportViewModel(repository: mock)
    vm.selectedDomainId = testCase.selectedDomainId
    vm.selectedTopicId = testCase.selectedTopicId

    await vm.loadIfNeeded()

    #expect(vm.headerTotalDuration == testCase.expected)
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

struct ReportViewModel_TimelineScrollStartTests {

  struct TestCase: CustomTestStringConvertible {
    let name: String
    let activities: [Activity]
    let expected: Date

    var testDescription: String { name }
  }

  static let cases: [TestCase] = [
    TestCase(
      name: "falls back to start of day when there are no activities",
      activities: [],
      expected: date(2026, 1, 1, 0)
    ),
    TestCase(
      name: "starts 3 hours before the first activity",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 5), endedAt: date(2026, 1, 1, 6)),
        activity(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 1, 8), endedAt: date(2026, 1, 1, 9)),
      ],
      expected: date(2026, 1, 1, 2)
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func timelineScrollStart_test(testCase: TestCase) async {
    let mock = MockActivityRepository()
    mock.activities = testCase.activities
    let vm = ReportViewModel(repository: mock)
    vm.currentDate = date(2026, 1, 1, 5)

    await vm.loadIfNeeded()

    #expect(vm.timelineScrollStart == testCase.expected)
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
    let selectedDomainId: String?
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
      selectedDomainId: nil,
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
      selectedDomainId: nil,
      targetBucketIndex: 3,
      expectedSegments: [
        ExpectedSegment(id: "d1", title: "Work", duration: 2 * 3600),
        ExpectedSegment(id: "d2", title: "Life", duration: 1 * 3600),
      ]
    ),
    TestCase(
      name: "groups by topic when a domain is selected",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        activity(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 1, 5), endedAt: date(2026, 1, 1, 6)),
      ],
      domains: domains,
      selectedDomainId: "d1",
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
      selectedDomainId: nil,
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
    vm.selectedDomainId = testCase.selectedDomainId

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
    let activities: [Activity]
    let domains: [Domain]
    let selectedDomainId: String?
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
      selectedDomainId: nil,
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
      name: "groups by topic when a domain is selected",
      activities: [
        activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 3)),
        activity(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 2, 1), endedAt: date(2026, 1, 2, 2)),
      ],
      domains: domains,
      selectedDomainId: "d1",
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
  ]

  @Test(arguments: cases)
  @MainActor
  func summaryRows_test(testCase: TestCase) async {
    let mock = MockActivityRepository()
    mock.activities = testCase.activities
    let vm = ReportViewModel(repository: mock)
    vm.periodType = .week
    vm.currentDate = date(2026, 1, 1)
    vm.selectedDomainId = testCase.selectedDomainId

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
    let selectedDomainId: String?
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
      name: "resolves domain title when no domain is selected",
      selectedDomainId: nil,
      id: "d1",
      expected: "Work"
    ),
    TestCase(
      name: "falls back to the id when no matching domain is found",
      selectedDomainId: nil,
      id: "unknown",
      expected: "unknown"
    ),
    TestCase(
      name: "resolves topic title within the selected domain",
      selectedDomainId: "d1",
      id: "t1",
      expected: "Coding"
    ),
    TestCase(
      name: "falls back to the id when the topic isn't in the selected domain",
      selectedDomainId: "d1",
      id: "unknown",
      expected: "unknown"
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func timelineTitle_test(testCase: TestCase) {
    let vm = ReportViewModel(repository: MockActivityRepository())
    vm.selectedDomainId = testCase.selectedDomainId

    #expect(vm.timelineTitle(for: testCase.id, domains: Self.domains) == testCase.expected)
  }

}

struct ReportViewModel_TimelineColorTests {

  struct TestCase: CustomTestStringConvertible {
    let name: String
    let selectedDomainId: String?
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
      name: "colors by domain index when no domain is selected",
      selectedDomainId: nil,
      activity: activity(domainId: "d2", topicId: "t9", startedAt: date(2026, 1, 1), endedAt: date(2026, 1, 1, 1)),
      expected: .orange
    ),
    TestCase(
      name: "colors by topic index within the domain when a domain is selected",
      selectedDomainId: "d1",
      activity: activity(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 1), endedAt: date(2026, 1, 1, 1)),
      expected: .orange
    ),
    TestCase(
      name: "falls back to gray when the id has no color mapping",
      selectedDomainId: nil,
      activity: activity(domainId: "unknown", topicId: "t9", startedAt: date(2026, 1, 1), endedAt: date(2026, 1, 1, 1)),
      expected: .gray
    ),
  ]

  @Test(arguments: cases)
  @MainActor
  func timelineColor_test(testCase: TestCase) {
    let vm = ReportViewModel(repository: MockActivityRepository())
    vm.selectedDomainId = testCase.selectedDomainId

    #expect(vm.timelineColor(for: testCase.activity, domains: Self.domains) == testCase.expected)
  }

}
