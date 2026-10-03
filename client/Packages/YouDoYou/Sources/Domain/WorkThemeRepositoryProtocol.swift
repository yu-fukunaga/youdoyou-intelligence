import Foundation

public protocol WorkThemeRepositoryProtocol: Sendable {
  func observe(onChange: @escaping ([WorkTheme]) -> Void) -> any ListenerHandle
  func add(_ workTheme: WorkTheme) async throws
  func update(_ workTheme: WorkTheme) async throws
  func delete(id: String) async throws
  func uploadTopicImage(topicId: String, data: Data) async throws -> String
}
