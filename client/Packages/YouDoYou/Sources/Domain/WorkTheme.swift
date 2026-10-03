import Foundation

public struct WorkTheme: Identifiable, Sendable {
  public var id: String
  public var title: String
  public var description: String
  public var topics: [Topic]
  public var color: String?
  public var createdAt: Date?
  public var updatedAt: Date?

  public init(
    id: String,
    title: String,
    description: String,
    topics: [Topic] = [],
    color: String? = nil,
    createdAt: Date? = nil,
    updatedAt: Date? = nil
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.topics = topics
    self.color = color
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}

public struct Topic: Identifiable, Sendable {
  public var id: String
  public var title: String
  public var imageUrl: String?

  public init(
    id: String,
    title: String,
    imageUrl: String? = nil
  ) {
    self.id = id
    self.title = title
    self.imageUrl = imageUrl
  }
}
