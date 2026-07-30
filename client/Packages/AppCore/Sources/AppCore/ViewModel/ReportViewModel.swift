import Foundation
import SwiftUI

// MARK: - Types

enum PeriodType: String, CaseIterable {
  case day = "Day"
  case week = "Week"
  case sixMonths = "6M"
  case fiveYears = "5Y"
}

enum GroupingUnit: String, CaseIterable {
  case domain = "Domain"
  case topic = "Topic"
}

struct BarChartSegment: Identifiable {
  let id: String
  let title: String
  let color: Color
  let duration: TimeInterval
}

struct BarChartColumn: Identifiable {
  // Positional (bucket index), not date-based: keeps the same identity across period
  // navigation so SwiftUI's ForEach recognizes "same column, new value" and animates
  // the bar's height in place instead of treating it as a brand new view.
  let id: Int
  let date: Date
  // Empty for padding columns beyond the current PeriodType's real bucket count (see
  // ReportViewModel.maxBarSlots) - real bucket labels are never empty. Keeps the column
  // count constant across PeriodType switches so bars animate in place instead of being
  // inserted/removed.
  let label: String
  let segments: [BarChartSegment]
  var isPlaceholder: Bool { label.isEmpty }
  var total: TimeInterval { segments.reduce(0) { $0 + $1.duration } }
}

struct ClockSegment: Identifiable {
  let id: String
  let color: Color
  let duration: TimeInterval
}

struct ListRow: Identifiable {
  let id: String
  let title: String
  let subtitle: String?
  let color: Color
  let bucketDurations: [TimeInterval]
  var total: TimeInterval { bucketDurations.reduce(0, +) }
}

// MARK: - ViewModel

@MainActor
class ReportViewModel: ObservableObject {
  @Published var periodType: PeriodType = .week
  @Published var currentDate: Date = .now
  @Published var groupingUnit: GroupingUnit = .domain {
    didSet { selectedItemId = nil }
  }
  @Published var selectedItemId: String?
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
    case .sixMonths:
      let year = cal.component(.year, from: currentDate)
      let month = cal.component(.month, from: currentDate)
      let startMonth = month <= 6 ? 1 : 7
      let start = cal.date(from: DateComponents(year: year, month: startMonth, day: 1))!
      let end = cal.date(byAdding: .month, value: 6, to: start)!
      return DateInterval(start: start, end: end)
    case .fiveYears:
      let year = cal.component(.year, from: currentDate)
      let start = cal.date(from: DateComponents(year: year - 4, month: 1, day: 1))!
      let end = cal.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
      return DateInterval(start: start, end: end)
    }
  }

  var headerDateRangeText: String {
    let interval = dateInterval
    let cal = calendar
    let lastDay = cal.date(byAdding: .day, value: -1, to: interval.end)!

    switch periodType {
    case .day:
      let f = DateFormatter()
      f.dateFormat = "yyyy/MM/dd"
      return f.string(from: interval.start)
    case .week:
      let startFormatter = DateFormatter()
      startFormatter.dateFormat = "yyyy年M月d日"
      let endFormatter = DateFormatter()
      endFormatter.dateFormat = "M月d日"
      return "\(startFormatter.string(from: interval.start))~\(endFormatter.string(from: lastDay))"
    case .sixMonths:
      let year = cal.component(.year, from: interval.start)
      let half = cal.component(.month, from: interval.start) <= 6 ? "前期" : "後期"
      return "\(year)年\(half)"
    case .fiveYears:
      let startYear = cal.component(.year, from: interval.start)
      let endYear = cal.component(.year, from: lastDay)
      return "\(startYear)年~\(endYear)年"
    }
  }

  // MARK: - Buckets (Week / 6M / 5Y only)

  var buckets: [DateInterval] {
    let cal = calendar
    let interval = dateInterval
    var result: [DateInterval] = []
    var current = interval.start

    let component: Calendar.Component = {
      switch periodType {
      case .day: return .hour  // unused
      case .week: return .day
      case .sixMonths: return .month
      case .fiveYears: return .year
      }
    }()

    while current < interval.end {
      let next = cal.date(byAdding: component, value: 1, to: current)!
      result.append(DateInterval(start: current, end: min(next, interval.end)))
      current = next
    }
    return result
  }

  // The largest bucket count across all non-Day PeriodTypes (Week's 7). Used to pad the
  // bar chart's column array to a constant length so PeriodType switches never insert or
  // remove columns (which would break their per-bar animation) - not used for `buckets`
  // itself, which must stay the real, PeriodType-dependent count (e.g. for averaging).
  static let maxBarSlots = 7

  func bucketLabel(for bucket: DateInterval) -> String {
    let cal = calendar
    switch periodType {
    case .day:
      return ""
    case .week:
      return cal.shortWeekdaySymbols[cal.component(.weekday, from: bucket.start) - 1]
    case .sixMonths:
      return "\(cal.component(.month, from: bucket.start))月"
    case .fiveYears:
      return "\(cal.component(.year, from: bucket.start))年"
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

  private func reload() async {
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
    case .sixMonths:
      component = .month
      value = 6 * offset
    case .fiveYears:
      component = .year
      value = 5 * offset
    }

    currentDate = cal.date(byAdding: component, value: value, to: currentDate)!
    Task { await loadIfNeeded() }
  }

  // MARK: - Filter

  func toggleItem(_ id: String) {
    selectedItemId = selectedItemId == id ? nil : id
  }

  private var filteredActivities: [Activity] {
    guard let selectedItemId else { return currentActivities }
    return currentActivities.filter { $0[keyPath: groupingKey] == selectedItemId }
  }

  // MARK: - Overall

  var headerTotalDuration: TimeInterval {
    filteredActivities.reduce(0) {
      $0 + $1.endedAt.timeIntervalSince($1.startedAt)
    }
  }

  // Average per bucket (day for Week, month for 6M, year for 5Y). Day has no
  // meaningful sub-bucket, so it's treated as a single bucket (average == total).
  var headerAverageDuration: TimeInterval {
    let count = periodType == .day ? 1 : buckets.count
    guard count > 0 else { return 0 }
    return headerTotalDuration / Double(count)
  }

  // MARK: - Timeline (Day)

  var timelineActivities: [Activity] {
    filteredActivities.sorted { $0.startedAt < $1.startedAt }
  }

  // The full day as an ordered sequence of segments covering all 24 hours (activities
  // plus the gaps between them), so a SectorMark chart built from this list lines up
  // with real clock positions instead of just being proportional slices.
  func clockSegments(domains: [Domain]) -> [ClockSegment] {
    let cal = calendar
    let dayStart = cal.startOfDay(for: currentDate)
    let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart)!
    let colorMap = colorMap(domains: domains)

    var segments: [ClockSegment] = []
    var cursor = dayStart

    for activity in timelineActivities {
      let start = max(max(activity.startedAt, dayStart), cursor)
      let end = min(activity.endedAt, dayEnd)
      guard start < end else { continue }

      if start > cursor {
        segments.append(
          ClockSegment(
            id: "gap-\(segments.count)", color: Color(.systemFill), duration: start.timeIntervalSince(cursor))
        )
      }

      let colorId = groupId(for: activity)
      segments.append(
        ClockSegment(
          id: activity.id ?? colorId, color: colorMap[colorId] ?? .gray, duration: end.timeIntervalSince(start))
      )
      cursor = end
    }

    if cursor < dayEnd {
      segments.append(
        ClockSegment(id: "gap-\(segments.count)", color: Color(.systemFill), duration: dayEnd.timeIntervalSince(cursor))
      )
    }

    return segments
  }

  func timelineTitle(for id: String, domains: [Domain]) -> String {
    switch groupingUnit {
    case .domain:
      return domains.first { $0.id == id }?.title ?? id
    case .topic:
      for domain in domains {
        if let topic = domain.topics.first(where: { $0.id == id }) {
          return topic.title
        }
      }
      return id
    }
  }

  func groupId(for activity: Activity) -> String {
    activity[keyPath: groupingKey]
  }

  func timelineColor(for activity: Activity, domains: [Domain]) -> Color {
    let colorMap = colorMap(domains: domains)
    let id = activity[keyPath: groupingKey]
    return colorMap[id] ?? .gray
  }

  // MARK: - Bar Chart (Week / 6M / 5Y)

  // Always includes every known group (domain or topic) per bucket, with 0 duration when
  // absent, so a segment's identity is stable across period navigation (a group that had
  // no activity before still "exists" at height 0, letting it grow from the bottom
  // instead of being freshly inserted and fading in).
  func barChartColumns(domains: [Domain]) -> [BarChartColumn] {
    let activities = filteredActivities
    let colorMap = colorMap(domains: domains)
    let allGroups = allGroupIds(domains: domains)
    let realBuckets = buckets

    return (0..<Self.maxBarSlots).map { index in
      guard index < realBuckets.count else {
        let placeholderSegments = allGroups.map { group in
          BarChartSegment(id: group.id, title: group.title, color: colorMap[group.id] ?? .gray, duration: 0)
        }
        return BarChartColumn(
          id: index, date: .distantPast, label: "", segments: placeholderSegments
        )
      }

      let bucket = realBuckets[index]
      let inBucket = activities.filter {
        $0.startedAt < bucket.end && bucket.start < $0.endedAt
      }

      let grouped = barChartSegments(inBucket, in: bucket, domains: domains)
      let durationById = Dictionary(uniqueKeysWithValues: grouped.map { ($0.id, $0.duration) })

      let segments = allGroups.map { group in
        BarChartSegment(
          id: group.id, title: group.title,
          color: colorMap[group.id] ?? .gray, duration: durationById[group.id] ?? 0
        )
      }

      return BarChartColumn(
        id: index, date: bucket.start, label: bucketLabel(for: bucket), segments: segments
      )
    }
  }

  private func allGroupIds(domains: [Domain]) -> [(id: String, title: String)] {
    switch groupingUnit {
    case .domain:
      return domains.map { (id: $0.id ?? "", title: $0.title) }
    case .topic:
      return domains.flatMap { domain in
        domain.topics.map { (id: $0.id, title: $0.title) }
      }
    }
  }

  // MARK: - List

  // Unfiltered total, used for the list's pinned "Total" row so it always
  // reflects everything regardless of the current selection.
  var listTotalDuration: TimeInterval {
    currentActivities.reduce(0) {
      $0 + $1.endedAt.timeIntervalSince($1.startedAt)
    }
  }

  // Uses currentActivities (not filteredActivities) so every row stays visible
  // for tapping even while another item is selected.
  func listRows(domains: [Domain]) -> [ListRow] {
    let activities = currentActivities
    let colorMap = colorMap(domains: domains)
    let allBuckets = buckets
    let groups = listGroups(in: activities, domains: domains)

    return groups.map { group in
      let durations = allBuckets.map { bucket in
        listBucketDuration(groupId: group.id, activities: activities, in: bucket)
      }
      let subtitle = groupingUnit == .topic ? domainTitle(forTopicId: group.id, domains: domains) : nil
      return ListRow(
        id: group.id, title: group.title, subtitle: subtitle,
        color: colorMap[group.id] ?? .gray, bucketDurations: durations
      )
    }
    .sorted { $0.total > $1.total }
  }

  // MARK: - Helpers

  private var groupingKey: KeyPath<Activity, String> {
    groupingUnit == .domain ? \.domainId : \.topicId
  }

  // One BarChartColumn's segments: groups only include activity within this bucket,
  // and groups with zero duration in this bucket are omitted.
  private func barChartSegments(
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
        groups[id] = (title: timelineTitle(for: id, domains: domains), duration: 0)
      }
      groups[id]!.duration += clamped
    }

    return groups.map {
      (id: $0.key, title: $0.value.title, duration: $0.value.duration)
    }
  }

  // One ListRow.bucketDurations entry: unlike barChartSegments, always returns
  // a value (0 if the group had no activity in this bucket).
  private func listBucketDuration(
    groupId: String,
    activities: [Activity],
    in bucket: DateInterval
  ) -> TimeInterval {
    activities
      .filter { $0[keyPath: groupingKey] == groupId }
      .reduce(0) { $0 + clampedDuration(activity: $1, in: bucket) }
  }

  // Clips the activity's duration to the bucket's boundaries; 0 if there's no overlap.
  private func clampedDuration(
    activity: Activity,
    in bucket: DateInterval
  ) -> TimeInterval {
    let start = max(activity.startedAt, bucket.start)
    let end = min(activity.endedAt, bucket.end)
    return max(0, end.timeIntervalSince(start))
  }

  private func listGroups(
    in activities: [Activity],
    domains: [Domain]
  ) -> [(id: String, title: String)] {
    let ids = Set(activities.map { $0[keyPath: groupingKey] })
    return ids.map { id in
      (id: id, title: timelineTitle(for: id, domains: domains))
    }
  }

  private func domainTitle(forTopicId topicId: String, domains: [Domain]) -> String? {
    domains.first { $0.topics.contains { $0.id == topicId } }?.title
  }

  private func colorMap(domains: [Domain]) -> [String: Color] {
    var map: [String: Color] = [:]
    for (i, domain) in domains.enumerated() {
      let color = Self.palette[i % Self.palette.count]
      map[domain.id ?? ""] = color
      for (j, topic) in domain.topics.enumerated() {
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
