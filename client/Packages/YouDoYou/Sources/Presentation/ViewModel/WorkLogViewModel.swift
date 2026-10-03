import Combine
import Domain
import Foundation

@MainActor
public class WorkLogViewModel: ObservableObject {
  @Published public var workLogs: [WorkLog] = []

  private let repository: any WorkLogRepositoryProtocol
  private var listener: (any ListenerHandle)?

  public var todayWorkLogs: [WorkLog] {
    workLogs.filter { Calendar.current.isDateInToday($0.startedAt) }
  }

  public var pastWorkLogs: [WorkLog] {
    workLogs.filter { !Calendar.current.isDateInToday($0.startedAt) }
  }

  public init(repository: any WorkLogRepositoryProtocol) {
    self.repository = repository
  }

  public func startObserving() {
    guard listener == nil else { return }
    listener = repository.observe { [weak self] workLogs in
      self?.workLogs = workLogs
    }
  }

  public func stopObserving() {
    listener?.remove()
    listener = nil
  }
}
