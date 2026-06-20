import Combine
import FirebaseFirestore
import Foundation
import YouDoYouFirestore

@MainActor
class DomainCreateViewModel: ObservableObject {
  @Published var isLoading = false
  @Published var error: String?

  private let repository: any DomainRepositoryProtocol

  init(repository: any DomainRepositoryProtocol = DomainRepository()) {
    self.repository = repository
  }

  func createDomain(title: String, description: String, topicTitles: [String]) async {
    isLoading = true
    defer { isLoading = false }
    let topics = topicTitles.map { Topic(id: UUID().uuidString, title: $0, imageUrl: "") }
    do {
      try await repository.create(title: title, description: description, topics: topics)
    }
    catch {
      self.error = error.localizedDescription
    }
  }
}
