import Domain
import SwiftUI

@MainActor
public class AppState: ObservableObject {
  @Published public private(set) var domains: [WorkTheme] = []
  @Published public private(set) var workTopics: [WorkTopic] = []

  public let repository: any WorkThemeRepositoryProtocol
  public let workTopicRepository: any WorkTopicRepositoryProtocol
  private var listener: (any ListenerHandle)?
  private var workTopicListener: (any ListenerHandle)?

  public init(
    repository: any WorkThemeRepositoryProtocol,
    workTopicRepository: any WorkTopicRepositoryProtocol
  ) {
    self.repository = repository
    self.workTopicRepository = workTopicRepository
  }

  public func start() {
    listener = repository.observe { [weak self] domains in
      self?.domains = domains
    }
    workTopicListener = workTopicRepository.observe { [weak self] workTopics in
      self?.workTopics = workTopics
    }
  }

  public func stop() {
    listener?.remove()
    listener = nil
    workTopicListener?.remove()
    workTopicListener = nil
  }
}
