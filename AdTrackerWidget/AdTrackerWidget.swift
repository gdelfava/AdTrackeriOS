//
//  AdTrackerWidget.swift
//  AdTrackerWidget
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import WidgetKit
import SwiftUI
import Intents

// Copy of AdSenseSummaryData for widget use (should match the main app)
struct AdSenseSummaryData: Codable {
    let today: String
    let yesterday: String
    let last7Days: String
    let thisMonth: String
    let lastMonth: String
    let lifetime: String
    let todayDelta: String?
    let todayDeltaPositive: Bool?
    let yesterdayDelta: String?
    let yesterdayDeltaPositive: Bool?
    let last7DaysDelta: String?
    let last7DaysDeltaPositive: Bool?
    let thisMonthDelta: String?
    let thisMonthDeltaPositive: Bool?
    let lastMonthDelta: String?
    let lastMonthDeltaPositive: Bool?
}

struct AdTrackerWidgetEntry: TimelineEntry {
    let date: Date
    let summary: AdSenseSummaryData?
    let lastUpdate: String
}

// Minimal AdSenseAPI for widget data loading
struct AdSenseAPI {
    static let appGroupID = "group.com.delteqws.AdTracker" // Must match main app
    static let summaryKey = "summaryData"
    static func loadSummaryFromSharedContainer() -> AdSenseSummaryData? {
        let defaults = UserDefaults(suiteName: appGroupID)
        if let data = defaults?.data(forKey: summaryKey),
           let summary = try? JSONDecoder().decode(AdSenseSummaryData.self, from: data) {
            return summary
        }
        return nil
    }

    static func loadLastUpdateDate() -> Date? {
        let defaults = UserDefaults(suiteName: appGroupID)
        return defaults?.object(forKey: "summaryLastUpdate") as? Date
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> AdTrackerWidgetEntry {
        AdTrackerWidgetEntry(date: Date(), summary: nil, lastUpdate: "--:--")
    }

    func getSnapshot(in context: Context, completion: @escaping (AdTrackerWidgetEntry) -> ()) {
        let summary = AdSenseAPI.loadSummaryFromSharedContainer()
        let lastUpdateDate = AdSenseAPI.loadLastUpdateDate() ?? Date()
        let entry = AdTrackerWidgetEntry(date: lastUpdateDate, summary: summary, lastUpdate: formattedTime(lastUpdateDate))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AdTrackerWidgetEntry>) -> ()) {
        let summary = AdSenseAPI.loadSummaryFromSharedContainer()
        let lastUpdateDate = AdSenseAPI.loadLastUpdateDate() ?? Date()
        let entry = AdTrackerWidgetEntry(date: lastUpdateDate, summary: summary, lastUpdate: formattedTime(lastUpdateDate))
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct AdTrackerWidgetEntryView: View {
    var entry: AdTrackerWidgetEntry

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                if let today = entry.summary?.today {
                    Text(today)
                        .font(.headline)
                        .fontWeight(.regular)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Text("--")
                        .font(.largeTitle)
                        .fontWeight(.regular)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                Text("Last update: \(formattedTime(entry.date))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                HStack {
                    if let delta = entry.summary?.todayDelta, let positive = entry.summary?.todayDeltaPositive {
                        HStack(spacing: 4) {
                            Image(systemName: positive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(positive ? .green : .red)
                                .font(.caption2)
                            Text(delta)
                                .font(.caption2)
                                .foregroundColor(positive ? .green : .red)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                    } else {
                        Text("-")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    //ZStack {
                      //  Circle()
                        //    .fill(Color.green)
                          //  .frame(width: 24, height: 24)
                        //Image(systemName: "chart.bar.fill")
                          //  .foregroundColor(.white)
                    //}
                }
            }
            .padding()
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// Helper for time formatting
private func formattedTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

struct AdTrackerWidget: Widget {
    let kind: String = "AdTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AdTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AdTracker Summary")
        .description("Shows today's earnings and delta.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
