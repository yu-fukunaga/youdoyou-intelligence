import Foundation

public protocol AuthRepositoryProtocol: Sendable {
  func observeAuthState(onChange: @escaping (User?) -> Void) -> any ListenerHandle
  func signIn(email: String, password: String) async throws
  func signInWithGoogle() async throws
  func signOut() throws
}
