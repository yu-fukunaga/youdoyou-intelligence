import Foundation

extension ProcessInfo {
  /// 現在の実行環境がXcode Preview（Canvas）であるかどうかを判定します
  public static var isPreview: Bool {
    processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }
}
