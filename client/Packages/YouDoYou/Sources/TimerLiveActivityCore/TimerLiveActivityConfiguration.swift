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
          Image("YouDoYouClientAppIcon")
            .resizable()
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.leading)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(timerInterval: context.attributes.startDate...Date.distantFuture, countsDown: false)
            .font(.system(.title3, design: .monospaced))
            .fontWeight(.bold)
            .foregroundStyle(.red)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 2) {
            Text(context.attributes.domainTitle)
              .font(.caption)
              .foregroundStyle(.secondary)
            Text(context.attributes.topicTitle)
              .font(.headline)
              .fontWeight(.semibold)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal)
          .padding(.top, 4)
        }
      } compactLeading: {
        Image("YouDoYouClientAppIcon")
          .resizable()
          .frame(width: 20, height: 20)
          .clipShape(RoundedRectangle(cornerRadius: 4))
      } compactTrailing: {
        Text(timerInterval: context.attributes.startDate...Date.distantFuture, countsDown: false)
          .font(.system(.caption, design: .monospaced))
          .fontWeight(.semibold)
          .foregroundStyle(.red)
          .frame(width: 44)
      } minimal: {
        Image("YouDoYouClientAppIcon")
          .resizable()
          .frame(width: 20, height: 20)
          .clipShape(RoundedRectangle(cornerRadius: 4))
      }
      .widgetURL(URL(string: "http://www.apple.com"))
      .keylineTint(Color.red)
    }
  }

  public init() {}
}
