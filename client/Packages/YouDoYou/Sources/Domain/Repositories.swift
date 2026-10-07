import Foundation

public protocol AuthRepositoryProtocol: Sendable {
  var currentUser: User? { get }
  func observeAuthState(onChange: @escaping (User?) -> Void) -> any ListenerHandle
  func signIn(email: String, password: String) async throws
  func signInWithGoogle() async throws
  func signOut() throws
}

public protocol WorkLogRepositoryProtocol: Sendable {
  func observe(onChange: @escaping ([WorkLog]) -> Void) -> any ListenerHandle
  func add(_ workLog: WorkLog) async throws
  func update(_ workLog: WorkLog) async throws
  func delete(id: String) async throws
  func query(from: Date, to: Date) async throws -> [WorkLog]
}

public protocol WorkTopicRepositoryProtocol: Sendable {
  func observe(onChange: @escaping ([WorkTopic]) -> Void) -> any ListenerHandle
  func add(_ workTopic: WorkTopic) async throws
  func update(_ workTopic: WorkTopic) async throws
  func delete(id: String) async throws
  func uploadImage(workTopicId: String, data: Data) async throws -> String
}
