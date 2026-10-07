import Domain
import Foundation

extension WorkLog {
  /// Converts the Firestore DTO into the hand-written domain model.
  /// Returns nil if `id` is unset, which only happens before Firestore assigns one.
  func toDomainModel() -> Domain.WorkLog? {
    guard let id else { return nil }
    return Domain.WorkLog(
      id: id,
      domainId: domainId,
      topicId: topicId,
      workTopicId: workTopicId,
      content: content,
      startedAt: startedAt,
      endedAt: endedAt,
      userId: userId,
      userName: userName,
      userIcon: userIcon,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
}

extension Domain.WorkLog {
  func toDTO() -> WorkLog {
    WorkLog(
      domainId: domainId,
      topicId: topicId,
      workTopicId: workTopicId,
      content: content,
      startedAt: startedAt,
      endedAt: endedAt,
      userId: userId,
      userName: userName,
      userIcon: userIcon
    )
  }
}
