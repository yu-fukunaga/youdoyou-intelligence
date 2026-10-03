import Domain
import FirebaseFirestore

/// Wraps a Firestore `ListenerRegistration` (a protocol, so it cannot itself
/// be retroactively declared to conform to `ListenerHandle`) behind our
/// Firebase-agnostic handle type.
struct FirestoreListenerHandle: ListenerHandle, @unchecked Sendable {
  private let registration: any ListenerRegistration

  init(_ registration: any ListenerRegistration) {
    self.registration = registration
  }

  func remove() {
    registration.remove()
  }
}
