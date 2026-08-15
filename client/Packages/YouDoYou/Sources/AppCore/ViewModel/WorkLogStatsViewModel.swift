import Combine
import FirebaseFirestore
import Foundation

@MainActor
class WorkLogStatsViewModel: ObservableObject {
  @Published var workLogs: [WorkLog] = []

  private let repository: any WorkLogRepositoryProtocol
  private var listener: ListenerRegistration?

  var todayWorkLogs: [WorkLog] {
    workLogs.filter { Calendar.current.isDateInToday($0.startedAt) }
  }

  var currentHour: Int {
    Calendar.current.component(.hour, from: Date())
  }

  var todayTotal: (hours: Int, minutes: Int) {
    let total = todayWorkLogs.reduce(0) { $0 + $1.endedAt.timeIntervalSince($1.startedAt) }
    return (Int(total) / 3600, (Int(total) % 3600) / 60)
  }

  var hourlyIntensity: [Int: Double] {
    let calendar = Calendar.current
    var totals: [Int: TimeInterval] = [:]

    for workLog in todayWorkLogs {
      var cursor = workLog.startedAt
      while cursor < workLog.endedAt {
        let hour = calendar.component(.hour, from: cursor)
        let hourStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: cursor) ?? cursor
        let nextHourStart = calendar.date(byAdding: .hour, value: 1, to: hourStart) ?? workLog.endedAt
        let segmentEnd = min(workLog.endedAt, nextHourStart)

        totals[hour, default: 0] += segmentEnd.timeIntervalSince(cursor)
        cursor = segmentEnd
      }
    }

    guard let maxDuration = totals.values.max(), maxDuration > 0 else { return [:] }
    return totals.mapValues { min($0 / maxDuration, 1.0) }
  }

  init(repository: any WorkLogRepositoryProtocol = WorkLogRepository()) {
    self.repository = repository
  }

  func startObserving() {
    guard listener == nil else { return }
    listener = repository.observe { [weak self] workLogs in
      self?.workLogs = workLogs
    }
  }

  func stopObserving() {
    listener?.remove()
    listener = nil
  }
}
