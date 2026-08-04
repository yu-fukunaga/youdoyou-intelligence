//
//  YouDoYou_WidgetsLiveActivity.swift
//  YouDoYou_Widgets
//
//  Created by 福永裕 on 2026/08/04.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct YouDoYou_WidgetsAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    // Dynamic stateful properties about your activity go here!
    var emoji: String
  }

  // Fixed non-changing properties about your activity go here!
  var name: String
}

struct YouDoYou_WidgetsLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: YouDoYou_WidgetsAttributes.self) { context in
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
}

extension YouDoYou_WidgetsAttributes {
  fileprivate static var preview: YouDoYou_WidgetsAttributes {
    YouDoYou_WidgetsAttributes(name: "World")
  }
}

extension YouDoYou_WidgetsAttributes.ContentState {
  fileprivate static var smiley: YouDoYou_WidgetsAttributes.ContentState {
    YouDoYou_WidgetsAttributes.ContentState(emoji: "😀")
  }

  fileprivate static var starEyes: YouDoYou_WidgetsAttributes.ContentState {
    YouDoYou_WidgetsAttributes.ContentState(emoji: "🤩")
  }
}

#Preview("Notification", as: .content, using: YouDoYou_WidgetsAttributes.preview) {
  YouDoYou_WidgetsLiveActivity()
} contentStates: {
  YouDoYou_WidgetsAttributes.ContentState.smiley
  YouDoYou_WidgetsAttributes.ContentState.starEyes
}
