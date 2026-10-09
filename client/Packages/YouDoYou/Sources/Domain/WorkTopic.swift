import Foundation

public struct WorkTopic: Identifiable, Sendable {
  public var id: String
  public var title: String
  public var description: String?
  public var imageUrl: String?
  public var createdAt: Date?
  public var updatedAt: Date?

  public init(
    id: String = UUID.v7().uuidString,
    title: String,
    description: String? = nil,
    imageUrl: String? = nil,
    createdAt: Date? = nil,
    updatedAt: Date? = nil
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.imageUrl = imageUrl
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
