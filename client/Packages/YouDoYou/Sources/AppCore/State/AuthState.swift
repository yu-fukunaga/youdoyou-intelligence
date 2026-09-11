import FirebaseAuth
import Foundation
import GoogleSignIn

#if canImport(UIKit)
  import UIKit
#endif

@MainActor
class AuthState: ObservableObject {
  @Published private(set) var user: User?
  @Published private(set) var isLoading = true

  private var listener: AuthStateDidChangeListenerHandle?

  init() {}

  var isAuthenticated: Bool {
    user != nil
  }

  func start() {
    listener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
      Task { @MainActor in
        self?.user = user
        self?.isLoading = false
      }
    }
  }

  func stop() {
    if let listener {
      Auth.auth().removeStateDidChangeListener(listener)
    }
    listener = nil
  }

  func signIn(email: String, password: String) async throws {
    try await Auth.auth().signIn(withEmail: email, password: password)
  }

  func signOut() throws {
    try Auth.auth().signOut()
  }

  func signInWithGoogle() async throws {
    #if os(iOS)
      guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let rootViewController = windowScene.keyWindow?.rootViewController
      else {
        throw NSError(
          domain: "AuthState", code: -1, userInfo: [NSLocalizedDescriptionKey: "Root view controller not found"])
      }
      let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
    #endif

    #if os(macOS)
      guard let window = NSApplication.shared.windows.first else {
        throw NSError(
          domain: "AuthState", code: -1, userInfo: [NSLocalizedDescriptionKey: "Main window not found"])
      }
      let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: window)
    #endif

    guard let idToken = result.user.idToken?.tokenString else {
      throw NSError(domain: "AuthState", code: -1, userInfo: [NSLocalizedDescriptionKey: "ID token not found"])
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

  #if DEBUG
    func signInAsTestUser() async throws {
      try await Auth.auth().signIn(
        withEmail: "test@example.com",
        password: "password"
      )
    }
  #endif

}
