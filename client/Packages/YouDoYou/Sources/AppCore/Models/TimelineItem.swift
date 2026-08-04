import Foundation

// ドメインモデル（ナビゲーション、ビジネスロジック用）
public struct TimelineItem: Hashable, Identifiable {
  public let id: String?
  public let domainId: String
  public let domainTitle: String
  public let content: String
  public let startedAt: Date
  public let endedAt: Date
  public let userId: String
  public let userName: String
  public let userIcon: String
  public let createdAt: Date

  public init(
    id: String? = nil, domainId: String, domainTitle: String, content: String, startedAt: Date, endedAt: Date,
    userId: String, userName: String, userIcon: String, createdAt: Date = Date()
  ) {
    self.id = id
    self.domainId = domainId
    self.domainTitle = domainTitle
    self.content = content
    self.startedAt = startedAt
    self.endedAt = endedAt
    self.userId = userId
    self.userName = userName
    self.userIcon = userIcon
    self.createdAt = createdAt
  }

  public var durationSeconds: TimeInterval {
    endedAt.timeIntervalSince(startedAt)
  }
}
