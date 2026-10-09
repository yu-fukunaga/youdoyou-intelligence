import Domain
import SwiftUI

@MainActor
public class AppState: ObservableObject {
  @Published public private(set) var workTopics: [WorkTopic] = []

  public let workTopicRepository: any WorkTopicRepositoryProtocol
  private var workTopicListener: (any ListenerHandle)?

  public init(workTopicRepository: any WorkTopicRepositoryProtocol) {
    self.workTopicRepository = workTopicRepository
  }

  public func start() {
    workTopicListener = workTopicRepository.observe { [weak self] workTopics in
      self?.workTopics = workTopics
    }
  }

  public func stop() {
    workTopicListener?.remove()
    workTopicListener = nil
  }
}
