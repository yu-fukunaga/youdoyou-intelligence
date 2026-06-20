import Combine
import FirebaseFirestore
import YouDoYouFirestore

@MainActor
class ActivityViewModel: ObservableObject {
  @Published var activities: [Activity] = []

  private let repository: ActivityRepositoryProtocol
  private var listener: ListenerRegistration?

  var todayActivities: [Activity] {
    activities.filter { Calendar.current.isDateInToday($0.startedAt) }
  }

  var pastActivities: [Activity] {
    activities.filter { !Calendar.current.isDateInToday($0.startedAt) }
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
