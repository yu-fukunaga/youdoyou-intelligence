import ActivityKit
import SwiftUI
import TimerLiveActivityAttributes
import WidgetKit

public struct TimerLiveActivity: Widget {
  public var body: some WidgetConfiguration {
    ActivityConfiguration(for: TimerLiveActivityAttributes.self) { context in
      // Lock screen/banner UI goes here
      VStack {
        Text("Hello \(context.state.emoji)")
      }
      .activityBackgroundTint(Color.cyan)
      .activitySystemActionForegroundColor(Color.black)

    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded UI goes here.  Compose the expanded UI through
        // various regions, like leading/trailing/center/bottom
        DynamicIslandExpandedRegion(.leading) {
          Text("Leading")
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("Trailing")
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text("Bottom \(context.state.emoji)")
          // more content
        }
      } compactLeading: {
        Text("L")
      } compactTrailing: {
        Text("T \(context.state.emoji)")
      } minimal: {
        Text(context.state.emoji)
      }
      .widgetURL(URL(string: "http://www.apple.com"))
      .keylineTint(Color.red)
    }
  }

  public init() {}
}

extension TimerLiveActivityAttributes {
  fileprivate static var preview: TimerLiveActivityAttributes {
    TimerLiveActivityAttributes(name: "World")
  }
}

extension TimerLiveActivityAttributes.ContentState {
  fileprivate static var smiley: TimerLiveActivityAttributes.ContentState {
    TimerLiveActivityAttributes.ContentState(emoji: "😀")
  }

  fileprivate static var starEyes: TimerLiveActivityAttributes.ContentState {
    TimerLiveActivityAttributes.ContentState(emoji: "🤩")
  }
}

#Preview("Notification", as: .content, using: TimerLiveActivityAttributes.preview) {
  TimerLiveActivity()
} contentStates: {
  TimerLiveActivityAttributes.ContentState.smiley
  TimerLiveActivityAttributes.ContentState.starEyes
}
