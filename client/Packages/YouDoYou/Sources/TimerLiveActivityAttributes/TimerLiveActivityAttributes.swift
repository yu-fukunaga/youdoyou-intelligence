#if os(iOS)
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
    public var title: String
    public var startDate: Date

    public init(title: String, startDate: Date) {
      self.title = title
      self.startDate = startDate
    }
  }
#endif
