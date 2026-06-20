import FirebaseFirestore
import Foundation

@MainActor
class ActivityDetailViewModel: ObservableObject {
  @Published var isDeleted = false
  @Published var isUpdated = false
  @Published var error: String?
  @Published var domain: Domain?
  @Published var topic: Topic?
  @Published var activity: Activity

  // 編集用
  @Published var content: String
  @Published var startDate: Date
  @Published var endDate: Date

  private let repository: any ActivityRepositoryProtocol

  var isEdited: Bool {
    content != activity.content || startDate != activity.startedAt || endDate != activity.endedAt
  }

  var isValid: Bool {
    !content.isEmpty && startDate < endDate
  }

  init(
    activity: Activity,
    appState: AppState,
    repository: any ActivityRepositoryProtocol = ActivityRepository()
  ) {
    self.activity = activity
    self.repository = repository
    self.content = activity.content
    self.startDate = activity.startedAt
    self.endDate = activity.endedAt
    self.domain = appState.domains.first { $0.id == activity.domainId }
    self.topic = domain?.topics.first { $0.id == activity.topicId }
  }

  func delete() async {
    guard let id = activity.id else { return }
    do {
      try await repository.delete(id: id)
      isDeleted = true
    }
    catch {
      self.error = error.localizedDescription
    }
  }

  func update() async {
    guard startDate < endDate else {
      error = "終了時間は開始時間より後に設定してください"
      return
    }

    var updated = activity
    updated.content = content
    updated.startedAt = startDate
    updated.endedAt = endDate

    do {
      try await repository.update(updated)
      activity = updated
      isUpdated = true
    }
    catch {
      self.error = error.localizedDescription
    }
  }
}
