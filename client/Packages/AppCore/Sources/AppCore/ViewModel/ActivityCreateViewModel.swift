import FirebaseAuth
import FirebaseFirestore
import Foundation

@MainActor
class ActivityCreateViewModel: ObservableObject {
  @Published var isLoading = false
  @Published var error: String?
  @Published var domain: Domain?
  @Published var topic: Topic?

  private let domainId: String
  private let topicId: String
  private let activityState: ActivityState
  private let repository: any ActivityRepositoryProtocol

  init(
    domainId: String,
    topicId: String,
    activityState: ActivityState,
    appState: AppState,
    repository: any ActivityRepositoryProtocol = ActivityRepository()
  ) {
    self.domainId = domainId
    self.topicId = topicId
    self.activityState = activityState
    self.repository = repository
    self.domain = appState.domains.first { $0.id == domainId }
    self.topic = domain?.topics.first { $0.id == topicId }
  }

  func startTimer() {
    activityState.start(domainId: domainId, topicId: topicId)
    error = nil
  }

  func stopTimer() {
    let elapsed = activityState.stop()
    if let start = activityState.startDate {
      activityState.endDate = start.addingTimeInterval(elapsed)
    }
  }

  func post() async {
    guard let user = Auth.auth().currentUser else {
      error = "ログインしてください"
      return
    }

    guard let start = activityState.startDate, let end = activityState.endDate, start < end else {
      error = "終了時間は開始時間より後に設定してください"
      return
    }

    isLoading = true
    defer { isLoading = false }

    let activity = Activity(
      domainId: domainId,
      topicId: topicId,
      content: activityState.content,
      startedAt: start,
      endedAt: end,
      userId: user.uid,
      userName: user.displayName ?? "ユーザー",
      userIcon: user.photoURL?.absoluteString ?? ""
    )

    do {
      try await repository.create(activity)
      activityState.reset()
    }
    catch {
      self.error = error.localizedDescription
    }
  }

  func cancel() {
    error = nil
    activityState.reset()
  }
}
