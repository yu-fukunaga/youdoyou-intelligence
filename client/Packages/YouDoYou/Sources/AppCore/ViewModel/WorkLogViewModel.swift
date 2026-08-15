import Combine
import FirebaseFirestore

@MainActor
class WorkLogViewModel: ObservableObject {
  @Published var workLogs: [WorkLog] = []

  private let repository: WorkLogRepositoryProtocol
  private var listener: ListenerRegistration?

  var todayWorkLogs: [WorkLog] {
    workLogs.filter { Calendar.current.isDateInToday($0.startedAt) }
  }

  var pastWorkLogs: [WorkLog] {
    workLogs.filter { !Calendar.current.isDateInToday($0.startedAt) }
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
