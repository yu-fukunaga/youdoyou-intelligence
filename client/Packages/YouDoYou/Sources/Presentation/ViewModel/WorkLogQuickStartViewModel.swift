import Combine
import Domain
import Foundation

@MainActor
public class WorkLogQuickStartViewModel: ObservableObject {
  @Published public var workLogs: [WorkLog] = []

  private let repository: any WorkLogRepositoryProtocol
  private var listener: (any ListenerHandle)?

  public init(repository: any WorkLogRepositoryProtocol) {
    self.repository = repository
  }

  public func startObserving() {
    guard listener == nil else { return }
    listener = repository.observe { [weak self] workLogs in
      self?.workLogs = workLogs
    }
  }

  public func stopObserving() {
    listener?.remove()
    listener = nil
  }

  // `workLogs` is already ordered most-recent-first by the repository.
  public func recentWorkTopics(in workTopics: [WorkTopic], limit: Int = 6) -> [WorkTopic] {
    var seenWorkTopicIds = Set<String>()
    var result: [WorkTopic] = []

    for workLog in workLogs {
      guard seenWorkTopicIds.insert(workLog.workTopicId).inserted else { continue }
      if let workTopic = workTopics.first(where: { $0.id == workLog.workTopicId }) {
        result.append(workTopic)
      }
      if result.count >= limit { break }
    }

    return result
  }
}
