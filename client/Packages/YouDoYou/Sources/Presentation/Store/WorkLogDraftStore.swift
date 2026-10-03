import ActivityKit
import Combine
import Domain
import Foundation
import Observation

#if os(iOS)
  import TimerLiveActivityAttributes
#endif

public enum WorkLogDraftStoreError: LocalizedError {
  case notLoggedIn
  case invalidTimeRange

  public var errorDescription: String? {
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
public final class WorkLogDraftStore {
  public var startDate: Date?
  public var endDate: Date?
  public var displayTime = "0:00:00"
  public var activeDomainId: String?
  public var activeTopicId: String?
  public var content: String = "" {
    didSet {
      if isRunning {
        UserDefaults.standard.set(content, forKey: Keys.content)
      }
    }
  }

  private let repository: any WorkLogRepositoryProtocol
  private let authRepository: any AuthRepositoryProtocol

  private var timerPublisher: AnyCancellable?

  public var isRunning: Bool {
    timerPublisher != nil
  }

  public var isReadyToPost: Bool {
    guard let start = startDate, let end = endDate else { return false }
    return start < end
  }

  private enum Keys {
    static let startDate = "timerStartedAt"
    static let domainId = "timerDomainId"
    static let topicId = "timerTopicId"
    static let domainTitle = "timerDomainTitle"
    static let topicTitle = "timerTopicTitle"
    static let content = "timerContent"
  }

  public init(repository: any WorkLogRepositoryProtocol, authRepository: any AuthRepositoryProtocol) {
    self.repository = repository
    self.authRepository = authRepository
    restore()
  }

  public func start(domainId: String, topicId: String) {
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

  public func startTimer(domainId: String, topicId: String, domainTitle: String, topicTitle: String) {
    start(domainId: domainId, topicId: topicId)
    UserDefaults.standard.set(domainTitle, forKey: Keys.domainTitle)
    UserDefaults.standard.set(topicTitle, forKey: Keys.topicTitle)
    requestLiveActivity(domainTitle: domainTitle, topicTitle: topicTitle)
  }

  private func requestLiveActivity(domainTitle: String, topicTitle: String) {
    #if os(iOS)
      do {
        _ = try ActivityKit.Activity<TimerLiveActivityAttributes>.request(
          attributes: TimerLiveActivityAttributes(
            domainTitle: domainTitle,
            topicTitle: topicTitle,
            startDate: startDate ?? Date()
          ),
          content: ActivityContent(
            state: TimerLiveActivityAttributes.ContentState(emoji: topicTitle),
            staleDate: nil
          ),
          pushType: nil
        )
      }
      catch {
        print("Failed to start Live Activity: \(error.localizedDescription)")
      }
    #endif
  }

  public func stopTimer() {
    guard startDate != nil else { return }
    timerPublisher?.cancel()
    timerPublisher = nil
    clearPersisted()
    endDate = Date()
    endLiveActivity()
  }

  public func post() async throws {
    guard let user = authRepository.currentUser else {
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
      userId: user.id,
      userName: user.displayName ?? "ユーザー",
      userIcon: user.photoURL?.absoluteString ?? ""
    )

    try await repository.add(workLog)
    reset()
  }

  public func reset() {
    timerPublisher?.cancel()
    timerPublisher = nil
    startDate = nil
    endDate = nil
    displayTime = "0:00:00"
    activeDomainId = nil
    activeTopicId = nil
    clearPersisted()
    endLiveActivity()
  }

  private func endLiveActivity() {
    #if os(iOS)
      Task {
        for activity in ActivityKit.Activity<TimerLiveActivityAttributes>.activities {
          await activity.end(nil, dismissalPolicy: .immediate)
        }
      }
    #endif
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

    var hasNoActiveLiveActivity = false
    #if os(iOS)
      hasNoActiveLiveActivity = ActivityKit.Activity<TimerLiveActivityAttributes>.activities.isEmpty
    #endif
    if hasNoActiveLiveActivity {
      let domainTitle = UserDefaults.standard.string(forKey: Keys.domainTitle) ?? ""
      let topicTitle = UserDefaults.standard.string(forKey: Keys.topicTitle) ?? ""
      requestLiveActivity(domainTitle: domainTitle, topicTitle: topicTitle)
    }
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
    UserDefaults.standard.removeObject(forKey: Keys.domainTitle)
    UserDefaults.standard.removeObject(forKey: Keys.topicTitle)
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
