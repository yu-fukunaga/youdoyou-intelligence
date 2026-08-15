import FirebaseFirestore

@testable import AppCore

final class MockWorkLogRepository: WorkLogRepositoryProtocol, @unchecked Sendable {
  var workLogs: [WorkLog] = []
  var stubbedError: Error?
  private(set) var queryCallCount = 0

  func observe(onChange: @escaping ([WorkLog]) -> Void) -> ListenerRegistration {
    return MockListenerRegistration()
  }
  func create(_ workLog: WorkLog) async throws {}
  func delete(id: String) async throws {}
  func update(_ workLog: WorkLog) async throws {}
  func query(from: Date, to: Date) async throws -> [WorkLog] {
    queryCallCount += 1
    if let stubbedError {
      throw stubbedError
    }
    return workLogs
  }
}

private class MockListenerRegistration: NSObject, ListenerRegistration {
  func remove() {}
}
