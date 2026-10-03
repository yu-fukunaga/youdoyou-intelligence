import Foundation

public protocol WorkLogRepositoryProtocol: Sendable {
  func observe(onChange: @escaping ([WorkLog]) -> Void) -> any ListenerHandle
  func add(_ workLog: WorkLog) async throws
  func update(_ workLog: WorkLog) async throws
  func delete(id: String) async throws
  func query(from: Date, to: Date) async throws -> [WorkLog]
}
