import Foundation

extension ProcessInfo {
  /// 現在の実行環境がXcode Preview（Canvas）であるかどうかを判定します
  static var isPreview: Bool {
    // プレビュー実行時、プロセス名には "Previews" という文字列が含まれます
    return processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }
}
