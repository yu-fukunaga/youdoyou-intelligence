import Domain
import Foundation

extension WorkTopic {
  /// Converts the Firestore DTO into the hand-written domain model.
  /// Returns nil if `id` is unset, which only happens before Firestore assigns one.
  func toDomainModel() -> Domain.WorkTopic? {
    guard let id else { return nil }
    return Domain.WorkTopic(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}

extension Domain.WorkTopic {
  func toDTO() -> WorkTopic {
    WorkTopic(
      title: title,
      description: description,
      imageUrl: imageUrl
    )
  }
}
