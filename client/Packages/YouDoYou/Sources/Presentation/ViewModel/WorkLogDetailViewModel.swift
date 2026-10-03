import Domain
import Foundation

@MainActor
public class WorkLogDetailViewModel: ObservableObject {
  @Published public var isDeleted = false
  @Published public var isUpdated = false
  @Published public var error: String?
  @Published public var domain: WorkTheme?
  @Published public var topic: Topic?
  @Published public var workLog: WorkLog

  // 編集用
  @Published public var content: String
  @Published public var startDate: Date
  @Published public var endDate: Date

  private let repository: any WorkLogRepositoryProtocol

  public var isEdited: Bool {
    content != workLog.content || startDate != workLog.startedAt || endDate != workLog.endedAt
  }

  public var isValid: Bool {
    !content.isEmpty && startDate < endDate
  }

  public init(
    workLog: WorkLog,
    appState: AppState,
    repository: any WorkLogRepositoryProtocol
  ) {
    self.workLog = workLog
    self.repository = repository
    self.content = workLog.content
    self.startDate = workLog.startedAt
    self.endDate = workLog.endedAt
    self.domain = appState.domains.first { $0.id == workLog.domainId }
    self.topic = domain?.topics.first { $0.id == workLog.topicId }
  }

  public func delete() async {
    do {
      try await repository.delete(id: workLog.id)
      isDeleted = true
    }
    catch {
      self.error = error.localizedDescription
    }
  }

  public func update() async {
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
