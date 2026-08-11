import Combine
import FirebaseFirestore
import Foundation

@MainActor
class ActivityQuickStartViewModel: ObservableObject {
  @Published var activities: [Activity] = []

  private let repository: any ActivityRepositoryProtocol
  private var listener: ListenerRegistration?

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

  // `activities` is already ordered most-recent-first by the repository.
  func recentTopics(in domains: [Domain], limit: Int = 6) -> [Topic] {
    let allTopics = domains.flatMap { $0.topics }
    var seenTopicIds = Set<String>()
    var result: [Topic] = []

    for activity in activities {
      guard seenTopicIds.insert(activity.topicId).inserted else { continue }
      if let topic = allTopics.first(where: { $0.id == activity.topicId }) {
        result.append(topic)
      }
      if result.count >= limit { break }
    }

    return result
  }
}
