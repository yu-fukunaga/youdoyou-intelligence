import Combine
import FirebaseFirestore
import Foundation

@MainActor
class ActivityStatsViewModel: ObservableObject {
  @Published var activities: [Activity] = []

  private let repository: any ActivityRepositoryProtocol
  private var listener: ListenerRegistration?

  var todayActivities: [Activity] {
    activities.filter { Calendar.current.isDateInToday($0.startedAt) }
  }

  var currentHour: Int {
    Calendar.current.component(.hour, from: Date())
  }

  var todayTotal: (hours: Int, minutes: Int) {
    let total = todayActivities.reduce(0) { $0 + $1.endedAt.timeIntervalSince($1.startedAt) }
    return (Int(total) / 3600, (Int(total) % 3600) / 60)
  }

  var hourlyIntensity: [Int: Double] {
    let calendar = Calendar.current
    var totals: [Int: TimeInterval] = [:]

    for activity in todayActivities {
      var cursor = activity.startedAt
      while cursor < activity.endedAt {
        let hour = calendar.component(.hour, from: cursor)
        let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: cursor) ?? cursor
        let nextHourStart = calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? activity.endedAt
        let segmentEnd = min(activity.endedAt, nextHourStart)

        totals[hour, default: 0] += segmentEnd.timeIntervalSince(cursor)
        cursor = segmentEnd
      }
    }

    guard let maxDuration = totals.values.max(), maxDuration > 0 else { return [:] }
    return totals.mapValues { min($0 / maxDuration, 1.0) }
  }

  init(repository: any ActivityRepositoryProtocol = ActivityRepository()) {
    self.repository = repository
  }

  func startObserving() {
    guard listener == nil else { return }
    listener = repository.observe { [weak self] activities in
      self?.activities = activities
    }
  }

  func stopObserving() {
    listener?.remove()
    listener = nil
  }
}
