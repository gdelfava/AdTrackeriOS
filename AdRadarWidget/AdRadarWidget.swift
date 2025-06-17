//
//  AdRadarWidget.swift
//  AdRadarWidget
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

struct AdRadarWidgetEntry: TimelineEntry {
    let date: Date
    let summary: AdSenseSummaryData?
    let lastUpdate: String
}

// Minimal AdSenseAPI for widget data loading
struct AdSenseAPI {
    static let appGroupID = "group.com.delteqws.AdRadar" // Must match main app
    static let summaryKey = "summaryData"
    
    static func loadSummaryFromSharedContainer() -> AdSenseSummaryData? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("[AdRadarWidget] Failed to access shared container")
            return nil
        }
        
        // Use a background queue for UserDefaults access
        return DispatchQueue.global(qos: .userInitiated).sync {
            guard let data = defaults.data(forKey: summaryKey) else {
                print("[AdRadarWidget] No summary data found in shared container")
                return nil
            }
            
            do {
                let summary = try JSONDecoder().decode(AdSenseSummaryData.self, from: data)
                print("[AdRadarWidget] Successfully loaded summary data from shared container")
                return summary
            } catch {
                print("[AdRadarWidget] Failed to decode summary data: \(error)")
                return nil
            }
        }
    }

    static func loadLastUpdateDate() -> Date? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("[AdRadarWidget] Failed to access shared container")
            return nil
        }
        
        // Use a background queue for UserDefaults access
        return DispatchQueue.global(qos: .userInitiated).sync {
            if let date = defaults.object(forKey: "summaryLastUpdate") as? Date {
                print("[AdRadarWidget] Successfully loaded last update date: \(date)")
                return date
            } else {
                print("[AdRadarWidget] No last update date found in shared container")
                return nil
            }
        }
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> AdRadarWidgetEntry {
        AdRadarWidgetEntry(date: Date(), summary: nil, lastUpdate: "--:--")
    }

    func getSnapshot(in context: Context, completion: @escaping (AdRadarWidgetEntry) -> ()) {
        // Always return placeholder for snapshot
        let entry = AdRadarWidgetEntry(date: Date(), summary: nil, lastUpdate: "--:--")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AdRadarWidgetEntry>) -> ()) {
        // Use a background queue for data loading
        DispatchQueue.global(qos: .userInitiated).async {
            let summary = AdSenseAPI.loadSummaryFromSharedContainer()
            let lastUpdateDate = AdSenseAPI.loadLastUpdateDate() ?? Date()
            let entry = AdRadarWidgetEntry(date: lastUpdateDate, summary: summary, lastUpdate: formattedTime(lastUpdateDate))
            
            // Update every hour instead of 30 minutes to reduce load
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            // Ensure we call completion on the main queue
            DispatchQueue.main.async {
                completion(timeline)
            }
        }
    }
}

struct EarningsCell: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Spacer()
                Text(value)
                    .font(.title2)
                    .bold()
            }
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
    }
}

// MARK: - WidgetCellView for Large Widget
struct WidgetCellView: View {
    let iconName: String
    let iconColor: Color
    let value: String
    let title: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 36) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.18))
                        .frame(width: 24, height: 24)
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                        .font(.system(size: 12, weight: .bold))
                }
                Text(title)
                    .font(.caption2)
                    .foregroundColor(colorScheme == .dark ? .white : .secondary)
                    .lineLimit(1)
                Spacer()
            }
            Spacer()
            HStack {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                Spacer()
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

struct AdRadarWidgetEntryView: View {
    var entry: AdRadarWidgetEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        (colorScheme == .dark ? Color.black : Color.white)
            .ignoresSafeArea()
        VStack(alignment: .leading, spacing: 2) {
            Spacer(minLength: 4)
            // Header
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                VStack(alignment: .leading){
                    Text("Today")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    HStack(spacing: 2) {
                        Text("Last Updated: ")
                            .font(.system(size: 10))
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(entry.lastUpdate)
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                }
                Spacer()
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("AdRadar for Adsense")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
            // Today value (reduce spacing)
            if let today = entry.summary?.today {
                Text(today)
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 8)
            } else {
                Text("--")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.top, 8)
            }
            // Row for Yesterday, This Month, Last Month
            Spacer(minLength: 4)
            HStack(alignment: .top, spacing: 2) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Yesterday")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)
                    Text(entry.summary?.yesterday ?? "--")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text("This Month")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)
                    Text(entry.summary?.thisMonth ?? "--")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Last Month")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.primary)
                    Text(entry.summary?.lastMonth ?? "--")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 4)
            Spacer(minLength: 0)
        }
        .padding([.leading, .trailing, .bottom, .top], 16)
        .containerBackground(colorScheme == .dark ? Color.black : Color.white, for: .widget)
    }
}

// Helper for time formatting
private func formattedTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

struct AdRadarWidget: Widget {
    let kind: String = "AdRadarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AdRadarWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AdRadar Summary")
        .description("Shows today's earnings and delta.")
        .supportedFamilies([.systemMedium])
    }
}
