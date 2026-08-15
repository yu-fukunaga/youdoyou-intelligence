import ActivityKit
import FirebaseAuth
import FirebaseFirestore
import Foundation
import TimerLiveActivityAttributes

@MainActor
class WorkLogCreateViewModel: ObservableObject {
  @Published var isLoading = false
  @Published var error: String?
  @Published var domain: Domain?
  @Published var topic: Topic?

  private let domainId: String
  private let topicId: String
  private let workLogState: WorkLogState
  private let repository: any WorkLogRepositoryProtocol

  init(
    domainId: String,
    topicId: String,
    workLogState: WorkLogState,
    appState: AppState,
    repository: any WorkLogRepositoryProtocol = WorkLogRepository()
  ) {
    self.domainId = domainId
    self.topicId = topicId
    self.workLogState = workLogState
    self.repository = repository
    self.domain = appState.domains.first { $0.id == domainId }
    self.topic = domain?.topics.first { $0.id == topicId }
  }

  func startTimer() {
    workLogState.start(domainId: domainId, topicId: topicId)
    error = nil
    do {
      try ActivityKit.Activity<TimerLiveActivityAttributes>.request(
        attributes: TimerLiveActivityAttributes(name: domain?.title ?? ""),
        contentState: TimerLiveActivityAttributes.ContentState(emoji: topic?.title ?? ""),
        pushType: nil
      )
    }
    catch {
      self.error = error.localizedDescription
    }
  }

  func stopTimer() {
    let elapsed = workLogState.stop()
    if let start = workLogState.startDate {
      workLogState.endDate = start.addingTimeInterval(elapsed)
    }
  }

  func post() async {
    guard let user = Auth.auth().currentUser else {
      error = "ログインしてください"
      return
    }

    guard let start = workLogState.startDate, let end = workLogState.endDate, start < end else {
      error = "終了時間は開始時間より後に設定してください"
      return
    }

    isLoading = true
    defer { isLoading = false }

    let workLog = WorkLog(
      domainId: domainId,
      topicId: topicId,
      content: workLogState.content,
      startedAt: start,
      endedAt: end,
      userId: user.uid,
      userName: user.displayName ?? "ユーザー",
      userIcon: user.photoURL?.absoluteString ?? ""
    )

    do {
      try await repository.create(workLog)
      workLogState.reset()
    }
    catch {
      self.error = error.localizedDescription
    }
  }

  func cancel() {
    error = nil
    workLogState.reset()
  }
}
