import Domain
import SwiftUI

@MainActor
public class AppState: ObservableObject {
  @Published public private(set) var domains: [WorkTheme] = []

  public let repository: any WorkThemeRepositoryProtocol
  private var listener: (any ListenerHandle)?

  public init(repository: any WorkThemeRepositoryProtocol) {
    self.repository = repository
  }

  public func start() {
    listener = repository.observe { [weak self] domains in
      self?.domains = domains
    }
  }

  public func stop() {
    listener?.remove()
    listener = nil
  }
}
