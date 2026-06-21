import Combine
import Foundation

@MainActor
class StopWatch: ObservableObject {
  @Published var displayTime = "00:00:00"
  @Published var isRunning = false

  private var startDate: Date?
  private var timerPublisher: AnyCancellable?

  /// タイマー開始
  func start() {
    startDate = Date()
    isRunning = true

    timerPublisher = Timer.publish(every: 1.0, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] now in
        self?.updateDisplayTime(currentDate: now)
      }
  }

  /// タイマー停止し、経過時間を返す
  func stop() -> TimeInterval {
    timerPublisher?.cancel()
    timerPublisher = nil
    isRunning = false

    guard let start = startDate else { return 0 }
    return Date().timeIntervalSince(start)
  }

  /// タイマーをリセット
  func reset() {
    timerPublisher?.cancel()
    timerPublisher = nil
    startDate = nil
    displayTime = "00:00:00"
    isRunning = false
  }

  /// 開始時刻を取得
  func getStartDate() -> Date? {
    startDate
  }

  private func updateDisplayTime(currentDate: Date) {
    guard let start = startDate else {
      displayTime = "00:00:00"
      return
    }

    let elapsed = currentDate.timeIntervalSince(start)
    let hours = Int(elapsed) / 3600
    let minutes = (Int(elapsed) % 3600) / 60
    let seconds = Int(elapsed) % 60

    displayTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }
}
