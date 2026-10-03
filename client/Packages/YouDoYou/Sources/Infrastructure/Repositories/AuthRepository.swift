import Domain
import FirebaseAuth
import Foundation
import GoogleSignIn

#if canImport(UIKit)
  import UIKit
#endif

public struct AuthRepository: AuthRepositoryProtocol, @unchecked Sendable {
  public init() {}

  public func observeAuthState(onChange: @escaping (Domain.User?) -> Void) -> any ListenerHandle {
    let handle = Auth.auth().addStateDidChangeListener { _, user in
      onChange(user.map(Self.toDomainUser))
    }
    return FirebaseAuthListenerHandle(handle)
  }

  public func signIn(email: String, password: String) async throws {
    try await Auth.auth().signIn(withEmail: email, password: password)
  }

  public func signOut() throws {
    try Auth.auth().signOut()
  }

  @MainActor
  public func signInWithGoogle() async throws {
    #if os(iOS)
      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let rootViewController = windowScene.keyWindow?.rootViewController
      else {
        throw NSError(
          domain: "AuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Root view controller not found"])
      }
      let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
    #endif

    #if os(macOS)
      guard let window = NSApplication.shared.windows.first else {
        throw NSError(
          domain: "AuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Main window not found"])
      }
      let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
    #endif

    guard let idToken = result.user.idToken?.tokenString else {
      throw NSError(
        domain: "AuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "ID token not found"])
    }

    let credential = GoogleAuthProvider.credential(
      withIDToken: idToken,
      accessToken: result.user.accessToken.tokenString
    )
    try await Auth.auth().signIn(with: credential)

    if let photoURL = result.user.profile?.imageURL(withDimension: 200),
      Auth.auth().currentUser?.photoURL == nil
    {
      let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
      changeRequest?.photoURL = photoURL
      try await changeRequest?.commitChanges()
    }
  }

  private static func toDomainUser(_ user: FirebaseAuth.User) -> Domain.User {
    Domain.User(
      id: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoURL: user.photoURL
    )
  }
}

private struct FirebaseAuthListenerHandle: ListenerHandle, @unchecked Sendable {
  private let handle: any NSObjectProtocol

  init(_ handle: any NSObjectProtocol) {
    self.handle = handle
  }

  func remove() {
    Auth.auth().removeStateDidChangeListener(handle)
  }
}
