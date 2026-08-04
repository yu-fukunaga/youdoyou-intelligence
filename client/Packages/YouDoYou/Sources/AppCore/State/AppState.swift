import FirebaseFirestore
import SwiftUI

@MainActor
class AppState: ObservableObject {
  @Published private(set) var domains: [Domain] = []

  private let repository: any DomainRepositoryProtocol
  private var listener: ListenerRegistration?

  init(repository: any DomainRepositoryProtocol = DomainRepository()) {
    self.repository = repository
  }

  func start() {
    listener = repository.observe { [weak self] domains in
      self?.domains = domains
    }
  }
  func stop() {
    listener?.remove()
    listener = nil
  }
}
