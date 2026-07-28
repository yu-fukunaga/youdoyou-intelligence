import Foundation
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

struct ReportViewModel_DateRangeTextTests {

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
  @MainActor
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
  @MainActor
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
        periodType: .quarter,
        bucketStart: date(2026, 1, 1),
        expected: "1/1"
      ),
      (
        periodType: .year,
        bucketStart: date(2026, 1, 1),
        expected: "1月"
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

  @Test
  @MainActor
  func loadIfNeeded_test() async {
    let mock = MockActivityRepository()
    let vm = ReportViewModel(repository: mock)

    await vm.loadIfNeeded()
    #expect(mock.queryCallCount == 1)
  }

}

struct ReportViewModel_ReloadTests {

  private struct DummyError: Error {}

  @Test
  @MainActor
  func reload_whenQueryThrows_doesNotCacheAndRetriesNextTime() async {
    let mock = MockActivityRepository()
    mock.stubbedError = DummyError()
    let vm = ReportViewModel(repository: mock)

    await vm.reload()

    #expect(mock.queryCallCount == 1)
    #expect(vm.totalDuration == 0)

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
      (periodType: .quarter, offset: 1, expected: date(2026, 3, 26)),  // +12 weeks
      (periodType: .quarter, offset: -1, expected: date(2025, 10, 9)),  // -12 weeks
      (periodType: .year, offset: 1, expected: date(2027, 1, 1)),
      (periodType: .year, offset: -1, expected: date(2025, 1, 1)),
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

struct ReportViewModel_TotalDurationTests {

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
  func totalDuration_test(testCase: TestCase) async {
    let mock = MockActivityRepository()
    mock.activities = testCase.activities
    let vm = ReportViewModel(repository: mock)
    vm.selectedDomainId = testCase.selectedDomainId
    vm.selectedTopicId = testCase.selectedTopicId

    await vm.reload()

    #expect(vm.totalDuration == testCase.expected)
  }

}

struct ReportViewModel_DayActivitiesTests {

  @Test
  @MainActor
  func dayActivities_test() async {
    let mock = MockActivityRepository()
    mock.activities = [
      activity(domainId: "d1", topicId: "t3", startedAt: date(2026, 1, 1, 2), endedAt: date(2026, 1, 1, 3)),
      activity(domainId: "d1", topicId: "t1", startedAt: date(2026, 1, 1, 0), endedAt: date(2026, 1, 1, 1)),
      activity(domainId: "d1", topicId: "t2", startedAt: date(2026, 1, 1, 1), endedAt: date(2026, 1, 1, 2)),
    ]
    let vm = ReportViewModel(repository: mock)

    await vm.reload()

    #expect(vm.dayActivities.map { $0.topicId } == ["t1", "t2", "t3"])
  }

}

struct ReportViewModel_DayScrollStartTests {

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
  func dayScrollStart_test(testCase: TestCase) async {
    let mock = MockActivityRepository()
    mock.activities = testCase.activities
    let vm = ReportViewModel(repository: mock)
    vm.currentDate = date(2026, 1, 1, 5)

    await vm.reload()

    #expect(vm.dayScrollStart == testCase.expected)
  }

}

struct ReportViewModel_ChartBarsTests {

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

    await vm.reload()

    let bars = vm.chartBars(domains: testCase.domains)
    let segments =
      bars[testCase.targetBucketIndex].segments
      .map { ExpectedSegment(id: $0.id, title: $0.title, duration: $0.duration) }
      .sorted { $0.id < $1.id }

    #expect(segments == testCase.expectedSegments.sorted { $0.id < $1.id })
  }

}
