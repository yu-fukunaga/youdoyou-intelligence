import FirebaseFirestore
import Foundation

@MainActor
class WorkLogDetailViewModel: ObservableObject {
  @Published var isDeleted = false
  @Published var isUpdated = false
  @Published var error: String?
  @Published var domain: Domain?
  @Published var topic: Topic?
  @Published var workLog: WorkLog

  // 編集用
  @Published var content: String
  @Published var startDate: Date
  @Published var endDate: Date

  private let repository: any WorkLogRepositoryProtocol

  var isEdited: Bool {
    content != workLog.content || startDate != workLog.startedAt || endDate != workLog.endedAt
  }

  var isValid: Bool {
    !content.isEmpty && startDate < endDate
  }

  init(
    workLog: WorkLog,
    appState: AppState,
    repository: any WorkLogRepositoryProtocol = WorkLogRepository()
  ) {
    self.workLog = workLog
    self.repository = repository
    self.content = workLog.content
    self.startDate = workLog.startedAt
    self.endDate = workLog.endedAt
    self.domain = appState.domains.first { $0.id == workLog.domainId }
    self.topic = domain?.topics.first { $0.id == workLog.topicId }
  }

  func delete() async {
    guard let id = workLog.id else { return }
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

    var updated = workLog
    updated.content = content
    updated.startedAt = startDate
    updated.endedAt = endDate

    do {
      try await repository.update(updated)
      workLog = updated
      isUpdated = true
    }
    catch {
      self.error = error.localizedDescription
    }
  }
}
