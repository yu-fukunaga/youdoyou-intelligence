import Foundation

public struct WorkLog: Identifiable, Sendable {
  public var id: String
  public var domainId: String
  public var topicId: String
  public var content: String
  public var startedAt: Date
  public var endedAt: Date
  public var userId: String
  public var userName: String
  public var userIcon: String
  public var createdAt: Date?
  public var updatedAt: Date?

  public init(
    id: String = UUID.v7().uuidString,
    domainId: String,
    topicId: String,
    content: String,
    startedAt: Date,
    endedAt: Date,
    userId: String,
    userName: String,
    userIcon: String,
    createdAt: Date? = nil,
    updatedAt: Date? = nil
  ) {
    self.id = id
    self.domainId = domainId
    self.topicId = topicId
    self.content = content
    self.startedAt = startedAt
    self.endedAt = endedAt
    self.userId = userId
    self.userName = userName
    self.userIcon = userIcon
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
