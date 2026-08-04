import Combine
import Foundation

@MainActor
class ActivityState: ObservableObject {
  @Published var startDate: Date?
  @Published var endDate: Date?
  @Published var displayTime = "0:00:00"
  @Published var activeDomainId: String?
  @Published var activeTopicId: String?
  @Published var content: String = "" {
    didSet {
      if isRunning {
        UserDefaults.standard.set(content, forKey: Keys.content)
      }
    }
  }

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

  init() {
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

  func stop() -> TimeInterval {
    timerPublisher?.cancel()
    timerPublisher = nil
    clearPersisted()

    guard let start = startDate else { return 0 }
    return Date().timeIntervalSince(start)
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
