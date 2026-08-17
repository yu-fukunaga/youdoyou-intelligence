import ActivityKit
import Combine
import FirebaseAuth
import Foundation
import Observation
import TimerLiveActivityAttributes

enum WorkLogDraftStoreError: LocalizedError {
  case notLoggedIn
  case invalidTimeRange

  var errorDescription: String? {
    switch self {
    case .notLoggedIn:
      return "ログインしてください"
    case .invalidTimeRange:
      return "終了時間は開始時間より後に設定してください"
    }
  }
}

@Observable
@MainActor
final class WorkLogDraftStore {
  var startDate: Date?
  var endDate: Date?
  var displayTime = "0:00:00"
  var activeDomainId: String?
  var activeTopicId: String?
  var content: String = "" {
    didSet {
      if isRunning {
        UserDefaults.standard.set(content, forKey: Keys.content)
      }
    }
  }

  private let repository: any WorkLogRepositoryProtocol

  private var timerPublisher: AnyCancellable?

  var isRunning: Bool {
    timerPublisher != nil
  }

  var isReadyToPost: Bool {
    guard let start = startDate, let end = endDate else { return false }
    return start < end
  }

  private enum Keys {
    static let startDate = "timerStartedAt"
    static let domainId = "timerDomainId"
    static let topicId = "timerTopicId"
    static let content = "timerContent"
  }

  init(repository: WorkLogRepositoryProtocol) {
    self.repository = repository
    restore()
  }

  func start(domainId: String, topicId: String) {
    let now = Date()
    startDate = now
    activeDomainId = domainId
    activeTopicId = topicId

    // 永続化
    UserDefaults.standard.set(now, forKey: Keys.startDate)
    UserDefaults.standard.set(domainId, forKey: Keys.domainId)
    UserDefaults.standard.set(topicId, forKey: Keys.topicId)

    startTicking()
  }

  func startTimer(domainId: String, topicId: String, domainTitle: String, topicTitle: String) {
    start(domainId: domainId, topicId: topicId)
    do {
      try ActivityKit.Activity<TimerLiveActivityAttributes>.request(
        attributes: TimerLiveActivityAttributes(name: domainTitle),
        contentState: TimerLiveActivityAttributes.ContentState(emoji: topicTitle),
        pushType: nil
      )
    }
    catch {
      print("Failed to start Live Activity: \(error.localizedDescription)")
    }
  }

  func stopTimer() {
    guard startDate != nil else { return }
    timerPublisher?.cancel()
    timerPublisher = nil
    clearPersisted()
    endDate = Date()
  }

  func post() async throws {
    guard let user = Auth.auth().currentUser else {
      throw WorkLogDraftStoreError.notLoggedIn
    }
    guard let start = startDate, let end = endDate, start < end else {
      throw WorkLogDraftStoreError.invalidTimeRange
    }

    let workLog = WorkLog(
      domainId: activeDomainId ?? "",
      topicId: activeTopicId ?? "",
      content: content,
      startedAt: start,
      endedAt: end,
      userId: user.uid,
      userName: user.displayName ?? "ユーザー",
      userIcon: user.photoURL?.absoluteString ?? ""
    )

    try await repository.create(workLog)
    reset()
  }

  func reset() {
    timerPublisher?.cancel()
    timerPublisher = nil
    startDate = nil
    endDate = nil
    displayTime = "0:00:00"
    activeDomainId = nil
    activeTopicId = nil
    clearPersisted()
  }

  // アプリ起動時に復元
  private func restore() {
    guard
      let startDate = UserDefaults.standard.object(forKey: Keys.startDate) as? Date,
      let domainId = UserDefaults.standard.string(forKey: Keys.domainId),
      let topicId = UserDefaults.standard.string(forKey: Keys.topicId)
    else { return }

    self.startDate = startDate
    self.activeDomainId = domainId
    self.activeTopicId = topicId
    self.content = UserDefaults.standard.string(forKey: Keys.content) ?? ""
    startTicking()
  }

  private func startTicking() {
    timerPublisher = Timer.publish(every: 1.0, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] now in
        self?.updateDisplayTime(currentDate: now)
      }
  }

  private func clearPersisted() {
    UserDefaults.standard.removeObject(forKey: Keys.startDate)
    UserDefaults.standard.removeObject(forKey: Keys.domainId)
    UserDefaults.standard.removeObject(forKey: Keys.topicId)
    UserDefaults.standard.removeObject(forKey: Keys.content)
  }

  private func updateDisplayTime(currentDate: Date) {
    guard let start = startDate else {
      displayTime = "0:00:00"
      return
    }

    let elapsed = currentDate.timeIntervalSince(start)
    let hours = Int(elapsed) / 3600
    let minutes = (Int(elapsed) % 3600) / 60
    let seconds = Int(elapsed) % 60
    displayTime = String(format: "%d:%02d:%02d", hours, minutes, seconds)
  }
}
