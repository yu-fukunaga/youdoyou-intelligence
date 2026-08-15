import Combine
import FirebaseFirestore
import Foundation

@MainActor
class WorkLogQuickStartViewModel: ObservableObject {
  @Published var workLogs: [WorkLog] = []

  private let repository: any WorkLogRepositoryProtocol
  private var listener: ListenerRegistration?

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

  // `workLogs` is already ordered most-recent-first by the repository.
  func recentTopics(in domains: [Domain], limit: Int = 6) -> [Topic] {
    let allTopics = domains.flatMap { $0.topics }
    var seenTopicIds = Set<String>()
    var result: [Topic] = []

    for workLog in workLogs {
      guard seenTopicIds.insert(workLog.topicId).inserted else { continue }
      if let topic = allTopics.first(where: { $0.id == workLog.topicId }) {
        result.append(topic)
      }
      if result.count >= limit { break }
    }

    return result
  }
}
