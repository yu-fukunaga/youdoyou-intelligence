import FirebaseFirestore

@testable import AppCore

final class MockActivityRepository: ActivityRepositoryProtocol, @unchecked Sendable {
  func observe(onChange: @escaping ([Activity]) -> Void) -> ListenerRegistration {
    return MockListenerRegistration()
  }
  func create(_ activity: Activity) async throws {}
  func delete(id: String) async throws {}
  func update(_ activity: Activity) async throws {}
  func query(from: Date, to: Date) async throws -> [Activity] {
    return []
  }
}

private class MockListenerRegistration: NSObject, ListenerRegistration {
  func remove() {}
}
