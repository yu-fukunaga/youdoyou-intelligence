import Domain
import Foundation
import SwiftUI

@MainActor
public class AuthState: ObservableObject {
  @Published public private(set) var user: User?
  @Published public private(set) var isLoading = true

  private let repository: any AuthRepositoryProtocol
  private var listener: (any ListenerHandle)?

  public init(repository: any AuthRepositoryProtocol) {
    self.repository = repository
  }

  public var isAuthenticated: Bool {
    user != nil
  }

  public func start() {
    listener = repository.observeAuthState { [weak self] user in
      Task { @MainActor in
        self?.user = user
        self?.isLoading = false
      }
    }
  }

  public func stop() {
    listener?.remove()
    listener = nil
  }

  public func signIn(email: String, password: String) async throws {
    try await repository.signIn(email: email, password: password)
  }

  public func signOut() throws {
    try repository.signOut()
  }

  public func signInWithGoogle() async throws {
    try await repository.signInWithGoogle()
  }

  #if DEBUG
    public func signInAsTestUser() async throws {
      try await repository.signIn(
        email: "test@example.com",
        password: "password"
      )
    }
  #endif
}
