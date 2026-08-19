import ActivityKit
import SwiftUI
import WidgetKit

public struct TimerLiveActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    // Dynamic stateful properties about your activity go here!
    public var emoji: String

    public init(emoji: String) {
      self.emoji = emoji
    }
  }

  // Fixed non-changing properties about your activity go here!
  public var domainTitle: String
  public var topicTitle: String
  public var startDate: Date

  public init(domainTitle: String, topicTitle: String, startDate: Date) {
    self.domainTitle = domainTitle
    self.topicTitle = topicTitle
    self.startDate = startDate
  }
}
