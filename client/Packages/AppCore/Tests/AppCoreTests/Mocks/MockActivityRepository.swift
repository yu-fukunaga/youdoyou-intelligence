import FirebaseFirestore

@testable import AppCore

final class MockActivityRepository: ActivityRepositoryProtocol, @unchecked Sendable {
  var activities: [Activity] = []
  var stubbedError: Error?
  private(set) var queryCallCount = 0

  func observe(onChange: @escaping ([Activity]) -> Void) -> ListenerRegistration {
    return MockListenerRegistration()
  }
  func create(_ activity: Activity) async throws {}
  func delete(id: String) async throws {}
  func update(_ activity: Activity) async throws {}
  func query(from: Date, to: Date) async throws -> [Activity] {
    queryCallCount += 1
    if let stubbedError {
      throw stubbedError
    }
    return activities
  }
}

private class MockListenerRegistration: NSObject, ListenerRegistration {
  func remove() {}
}
