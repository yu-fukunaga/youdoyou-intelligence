import Domain
import Foundation

extension WorkTheme {
  /// Converts the Firestore DTO into the hand-written domain model.
  /// Returns nil if `id` is unset, which only happens before Firestore assigns one.
  func toDomainModel() -> Domain.WorkTheme? {
    guard let id else { return nil }
    return Domain.WorkTheme(
      id: id,
      title: title,
      description: description,
      topics: topics.map { $0.toDomainModel() },
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}

extension Domain.WorkTheme {
  func toDTO() -> WorkTheme {
    WorkTheme(
      title: title,
      description: description,
      topics: topics.map { $0.toDTO() },
      color: color
    )
  }
}

extension Topic {
  func toDomainModel() -> Domain.Topic {
    Domain.Topic(id: id, title: title, imageUrl: imageUrl)
  }
}

extension Domain.Topic {
  func toDTO() -> Topic {
    Topic(id: id, title: title, imageUrl: imageUrl)
  }
}
