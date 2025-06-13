//
//  AdTrackerWidgetLiveActivity.swift
//  AdTrackerWidget
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AdTrackerWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct AdTrackerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AdTrackerWidgetAttributes.self) { context in
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

extension AdTrackerWidgetAttributes {
    fileprivate static var preview: AdTrackerWidgetAttributes {
        AdTrackerWidgetAttributes(name: "World")
    }
}

extension AdTrackerWidgetAttributes.ContentState {
    fileprivate static var smiley: AdTrackerWidgetAttributes.ContentState {
        AdTrackerWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: AdTrackerWidgetAttributes.ContentState {
         AdTrackerWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: AdTrackerWidgetAttributes.preview) {
   AdTrackerWidgetLiveActivity()
} contentStates: {
    AdTrackerWidgetAttributes.ContentState.smiley
    AdTrackerWidgetAttributes.ContentState.starEyes
}
