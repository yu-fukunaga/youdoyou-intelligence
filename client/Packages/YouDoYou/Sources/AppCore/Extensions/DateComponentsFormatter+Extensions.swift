import Foundation

extension DateComponentsFormatter {
  // 「1:30:00」のような形式
  static let positional: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .positional  // 00:00:00 形式
    formatter.zeroFormattingBehavior = .pad  // 0埋め
    return formatter
  }()

  // 「1時間30分」のような形式
  static let abbreviated: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.unitsStyle = .abbreviated  // 単位を表示
    formatter.calendar = Calendar.current
    return formatter
  }()
}
