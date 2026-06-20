import Foundation
import SwiftUI

// MARK: - Types

enum PeriodType: String, CaseIterable {
  case day = "Day"
  case week = "Week"
  case quarter = "Quarter"
  case year = "Year"
}

struct ChartSegment: Identifiable {
  let id: String
  let title: String
  let color: Color
  let duration: TimeInterval
}

struct ChartBar: Identifiable {
  var id: Date { date }
  let date: Date
  let label: String
  let segments: [ChartSegment]
  var total: TimeInterval { segments.reduce(0) { $0 + $1.duration } }
}

struct SummaryRow: Identifiable {
  let id: String
  let title: String
  let color: Color
  let bucketDurations: [TimeInterval]
  var total: TimeInterval { bucketDurations.reduce(0, +) }
}

// MARK: - ViewModel

@MainActor
class ReportViewModel: ObservableObject {
  @Published var periodType: PeriodType = .week
  @Published var currentDate: Date = .now
  @Published var selectedDomainId: String?
  @Published var selectedTopicId: String?
  @Published private(set) var isLoading = false

  private var cache: [String: [Activity]] = [:]
  private var repository: any ActivityRepositoryProtocol
  private var calendar: Calendar

  private static let palette: [Color] = [
    .red, .orange, .yellow, .green, .teal,
    .blue, .indigo, .purple, .pink, .mint,
  ]

  init(
    repository: any ActivityRepositoryProtocol = ActivityRepository(),
    calendar: Calendar = {
      var cal = Calendar.current
      cal.firstWeekday = 2
      return cal
    }()
  ) {
    self.repository = repository
    self.calendar = calendar
  }

  // MARK: - Date Interval

  var dateInterval: DateInterval {
    let cal = calendar
    switch periodType {
    case .day:
      let start = cal.startOfDay(for: currentDate)
      return DateInterval(start: start, duration: 86400)
    case .week:
      return cal.dateInterval(of: .weekOfYear, for: currentDate)!
    case .quarter:
      let weekEnd = cal.dateInterval(of: .weekOfYear, for: currentDate)!.end
      let weekStart = cal.dateInterval(of: .weekOfYear, for: currentDate)!.start
      let start = cal.date(byAdding: .weekOfYear, value: -11, to: weekStart)!
      return DateInterval(start: start, end: weekEnd)
    case .year:
      return cal.dateInterval(of: .year, for: currentDate)!
    }
  }

  var dateRangeText: String {
    let f = DateFormatter()
    let interval = dateInterval
    let cal = calendar
    let lastDay = cal.date(byAdding: .day, value: -1, to: interval.end)!

    switch periodType {
    case .day:
      f.dateFormat = "yyyy/MM/dd"
      return f.string(from: interval.start)
    case .week, .quarter:
      f.dateFormat = "yyyy/MM/dd"
      return "\(f.string(from: interval.start)) - \(f.string(from: lastDay))"
    case .year:
      f.dateFormat = "yyyy年"
      return f.string(from: interval.start)
    }
  }

  // MARK: - Buckets (Week / Quarter / Year only)

  var buckets: [DateInterval] {
    let cal = calendar
    let interval = dateInterval
    var result: [DateInterval] = []
    var current = interval.start

    let component: Calendar.Component = {
      switch periodType {
      case .day: return .hour  // unused
      case .week: return .day
      case .quarter: return .weekOfYear
      case .year: return .month
      }
    }()

    while current < interval.end {
      let next = cal.date(byAdding: component, value: 1, to: current)!
      result.append(DateInterval(start: current, end: min(next, interval.end)))
      current = next
    }
    return result
  }

  func bucketLabel(for bucket: DateInterval) -> String {
    let cal = calendar
    switch periodType {
    case .day:
      return ""
    case .week:
      return cal.shortWeekdaySymbols[cal.component(.weekday, from: bucket.start) - 1]
    case .quarter:
      let f = DateFormatter()
      f.dateFormat = "M/d"
      return f.string(from: bucket.start)
    case .year:
      return "\(cal.component(.month, from: bucket.start))月"
    }
  }

  // MARK: - Fetch

  private var cacheKey: String {
    "\(periodType.rawValue)-\(dateInterval.start.timeIntervalSince1970)"
  }

  private var currentActivities: [Activity] {
    cache[cacheKey] ?? []
  }

  func loadIfNeeded() async {
    guard cache[cacheKey] == nil else { return }
    await reload()
  }

  func reload() async {
    let interval = dateInterval
    isLoading = true
    defer { isLoading = false }

    do {
      let results = try await repository.query(from: interval.start, to: interval.end)
      cache[cacheKey] = results
    }
    catch {
      print(error)
    }
  }

  // MARK: - Navigation

  func movePeriod(by offset: Int) {
    let cal = calendar
    let component: Calendar.Component
    let value: Int

    switch periodType {
    case .day:
      component = .day
      value = offset
    case .week:
      component = .weekOfYear
      value = offset
    case .quarter:
      component = .weekOfYear
      value = 12 * offset
    case .year:
      component = .year
      value = offset
    }

    currentDate = cal.date(byAdding: component, value: value, to: currentDate)!
    Task { await loadIfNeeded() }
  }

  // MARK: - Filter

  func selectDomain(_ domainId: String?) {
    if selectedDomainId == domainId {
      selectedDomainId = nil
    }
    else {
      selectedDomainId = domainId
    }
    selectedTopicId = nil
  }

  func toggleTopic(_ topicId: String) {
    selectedTopicId = selectedTopicId == topicId ? nil : topicId
  }

  private var filteredActivities: [Activity] {
    var result = currentActivities
    if let domainId = selectedDomainId {
      result = result.filter { $0.domainId == domainId }
    }
    if let topicId = selectedTopicId {
      result = result.filter { $0.topicId == topicId }
    }
    return result
  }

  // MARK: - Aggregation

  var totalDuration: TimeInterval {
    filteredActivities.reduce(0) {
      $0 + $1.endedAt.timeIntervalSince($1.startedAt)
    }
  }

  // Day timeline
  var dayActivities: [Activity] {
    filteredActivities.sorted { $0.startedAt < $1.startedAt }
  }

  var dayScrollStart: Date {
    let cal = calendar
    let dayStart = cal.startOfDay(for: currentDate)
    guard let first = dayActivities.first else { return dayStart }
    return cal.date(byAdding: .hour, value: -3, to: first.startedAt) ?? dayStart
  }

  // Bar charts
  func chartBars(domains: [Domain]) -> [ChartBar] {
    let activities = filteredActivities
    let colorMap = buildColorMap(domains: domains)

    return buckets.map { bucket in
      let inBucket = activities.filter {
        $0.startedAt < bucket.end && bucket.start < $0.endedAt
      }

      let grouped = groupByCurrentLevel(inBucket, in: bucket, domains: domains)
      var segments = grouped.map {
        ChartSegment(
          id: $0.id, title: $0.title,
          color: colorMap[$0.id] ?? .gray, duration: $0.duration
        )
      }

      if segments.isEmpty {
        segments.append(ChartSegment(id: "empty", title: "", color: .clear, duration: 0))
      }

      return ChartBar(
        date: bucket.start, label: bucketLabel(for: bucket), segments: segments
      )
    }
  }

  func summaryRows(domains: [Domain]) -> [SummaryRow] {
    let activities = filteredActivities
    let colorMap = buildColorMap(domains: domains)
    let allBuckets = buckets
    let groups = uniqueGroups(in: activities, domains: domains)

    return groups.map { group in
      let durations = allBuckets.map { bucket in
        durationFor(groupId: group.id, activities: activities, in: bucket)
      }
      return SummaryRow(
        id: group.id, title: group.title,
        color: colorMap[group.id] ?? .gray, bucketDurations: durations
      )
    }
    .sorted { $0.total > $1.total }
  }

  // MARK: - Helpers

  private var groupingKey: KeyPath<Activity, String> {
    selectedDomainId != nil ? \.topicId : \.domainId
  }

  private func groupByCurrentLevel(
    _ activities: [Activity],
    in bucket: DateInterval,
    domains: [Domain]
  ) -> [(id: String, title: String, duration: TimeInterval)] {
    var groups: [String: (title: String, duration: TimeInterval)] = [:]

    for activity in activities {
      let id = activity[keyPath: groupingKey]
      let clamped = clampedDuration(activity: activity, in: bucket)
      guard clamped > 0 else { continue }

      if groups[id] == nil {
        groups[id] = (title: resolveTitle(id: id, domains: domains), duration: 0)
      }
      groups[id]!.duration += clamped
    }

    return groups.map {
      (id: $0.key, title: $0.value.title, duration: $0.value.duration)
    }
  }

  private func durationFor(
    groupId: String,
    activities: [Activity],
    in bucket: DateInterval
  ) -> TimeInterval {
    activities
      .filter { $0[keyPath: groupingKey] == groupId }
      .reduce(0) { $0 + clampedDuration(activity: $1, in: bucket) }
  }

  private func clampedDuration(
    activity: Activity,
    in bucket: DateInterval
  ) -> TimeInterval {
    let start = max(activity.startedAt, bucket.start)
    let end = min(activity.endedAt, bucket.end)
    return max(0, end.timeIntervalSince(start))
  }

  private func uniqueGroups(
    in activities: [Activity],
    domains: [Domain]
  ) -> [(id: String, title: String)] {
    let ids = Set(activities.map { $0[keyPath: groupingKey] })
    return ids.map { id in
      (id: id, title: resolveTitle(id: id, domains: domains))
    }
  }

  func resolveTitle(id: String, domains: [Domain]) -> String {
    if selectedDomainId != nil {
      let domain = domains.first { $0.id == selectedDomainId }
      return domain?.topics.first { $0.id == id }?.title ?? id
    }
    else {
      return domains.first { $0.id == id }?.title ?? id
    }
  }

  func colorForActivity(_ activity: Activity, domains: [Domain]) -> Color {
    let colorMap = buildColorMap(domains: domains)
    let id = activity[keyPath: groupingKey]
    return colorMap[id] ?? .gray
  }

  private func buildColorMap(domains: [Domain]) -> [String: Color] {
    var map: [String: Color] = [:]
    for (i, domain) in domains.enumerated() {
      let color = Self.palette[i % Self.palette.count]
      map[domain.id ?? ""] = color
        for (j, topic) in (domain.topics).enumerated() {
            map[topic.id] = Self.palette[(i + j) % Self.palette.count]
      }
    }
    return map
  }
}

// MARK: - Duration Formatting

extension TimeInterval {
  var reportText: String {
    let totalMinutes = Int(self) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours == 0 { return String(format: "%d分", minutes) }
    if minutes == 0 { return String(format: "%d時間", hours) }
    return String(format: "%d時間%d分", hours, minutes)
  }
}
