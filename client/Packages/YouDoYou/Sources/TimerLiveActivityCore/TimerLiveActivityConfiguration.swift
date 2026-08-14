import ActivityKit
import SwiftUI
import TimerLiveActivityAttributes
import WidgetKit

public struct TimerLiveActivityConfiguration: Widget {
  public var body: some WidgetConfiguration {
    ActivityConfiguration(for: TimerLiveActivityAttributes.self) { context in
      // Lock screen/banner UI goes here
      HStack(spacing: 12) {
        Image("YouDoYouClientAppIcon")
          .resizable()
          .frame(width: 36, height: 36)
          .clipShape(RoundedRectangle(cornerRadius: 8))

        VStack(alignment: .leading, spacing: 2) {
          Text(context.attributes.domainTitle)
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(context.attributes.topicTitle)
            .font(.headline)
            .fontWeight(.semibold)
        }
        Spacer()
        Text(timerInterval: context.attributes.startDate...Date.distantFuture, countsDown: false)
          .font(.system(.title3, design: .monospaced))
          .fontWeight(.bold)
          .foregroundStyle(.red)
          .frame(width: 72, alignment: .trailing)
      }
      .padding(16)
      .activityBackgroundTint(Color(.systemBackground))
      .activitySystemActionForegroundColor(.primary)

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
    TimerLiveActivityAttributes(domainTitle: "Work", topicTitle: "World", startDate: Date())
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
  TimerLiveActivityConfiguration()
} contentStates: {
  TimerLiveActivityAttributes.ContentState.smiley
  TimerLiveActivityAttributes.ContentState.starEyes
}
