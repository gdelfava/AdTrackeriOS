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
        if let defaults = UserDefaults(suiteName: appGroupID) {
            return defaults.object(forKey: "summaryLastUpdate") as? Date
        }
        return nil
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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Set background color based on color scheme
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Today")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(entry.lastUpdate)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                }
                // Main value
                if let today = entry.summary?.today {
                    Text(today)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("--")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                // Delta indicator
                if let delta = entry.summary?.todayDelta, let positive = entry.summary?.todayDeltaPositive {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Image(systemName: positive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .semibold))
                        Text(delta)
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(positive ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background((positive ? Color.green : Color.red).opacity(0.15))
                    .clipShape(Capsule())
                }
                Spacer(minLength: 0)
                // App icon and name
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("AdsenseTracker")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
            .padding(12)
        }
        .containerBackground(colorScheme == .dark ? Color.black : Color.white, for: .widget)
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
