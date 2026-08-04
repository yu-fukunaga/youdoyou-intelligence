import FirebaseFirestore
import Foundation

// Firestore保存用のドキュメントモデル
public struct TimelineItemDocument: Codable {
  @DocumentID public var id: String?
  public var domainId: String
  public var domainTitle: String
  public var content: String
  public var startedAt: Date
  public var endedAt: Date
  public var userId: String
  public var userName: String
  public var userIcon: String
  @ServerTimestamp public var createdAt: Date?

  public init(
    domainId: String, domainTitle: String, content: String, startedAt: Date, endedAt: Date,
    userId: String, userName: String, userIcon: String
  ) {
    self.domainId = domainId
    self.domainTitle = domainTitle
    self.content = content
    self.startedAt = startedAt
    self.endedAt = endedAt
    self.userId = userId
    self.userName = userName
    self.userIcon = userIcon
  }
}
