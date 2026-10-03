import Domain
import Foundation

final class MockWorkLogRepository: WorkLogRepositoryProtocol, @unchecked Sendable {
  var workLogs: [WorkLog] = []
  var stubbedError: Error?
  private(set) var queryCallCount = 0

  func observe(onChange: @escaping ([WorkLog]) -> Void) -> any ListenerHandle {
    MockListenerHandle()
  }
  func add(_ workLog: WorkLog) async throws {}
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

private struct MockListenerHandle: ListenerHandle {
  func remove() {}
}
