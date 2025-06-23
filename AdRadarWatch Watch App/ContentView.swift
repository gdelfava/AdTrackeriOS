//
//  ContentView.swift
//  AdRadarWatch Watch App
//
//  Created by Guilio Del Fava on 2025/06/23.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var dataManager = WatchDataManager.shared
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: 4)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if let summaryData = dataManager.summaryData {
                        // Hero Today Card - Enhanced
                        HeroTodayCard(
                            earnings: summaryData.formattedTodayEarnings,
                            delta: summaryData.todayDelta,
                            deltaPositive: summaryData.todayDeltaPositive
                        )
                        .opacity(cardAppearances[0] ? 1 : 0)
                        .offset(y: cardAppearances[0] ? 0 : 20)
                        
                        // Recent Performance Section
                        VStack(spacing: 8) {
                            SectionHeader(title: "Recent", icon: "clock.fill")
                            
                            VStack(spacing: 6) {
                                CompactEarningsCard(
                                    title: "Yesterday",
                                    earnings: summaryData.formattedYesterdayEarnings,
                                    delta: summaryData.yesterdayDelta,
                                    deltaPositive: summaryData.yesterdayDeltaPositive,
                                    color: .orange
                                )
                                .opacity(cardAppearances[1] ? 1 : 0)
                                .offset(y: cardAppearances[1] ? 0 : 15)
                                
                                CompactEarningsCard(
                                    title: "Last 7 Days",
                                    earnings: summaryData.formattedLast7DaysEarnings,
                                    delta: summaryData.last7DaysDelta,
                                    deltaPositive: summaryData.last7DaysDeltaPositive,
                                    color: .blue
                                )
                                .opacity(cardAppearances[2] ? 1 : 0)
                                .offset(y: cardAppearances[2] ? 0 : 15)
                            }
                        }
                        
                        // Monthly Overview Section
                        VStack(spacing: 8) {
                            SectionHeader(title: "Monthly", icon: "calendar.circle.fill")
                            
                            HStack(spacing: 6) {
                                MonthlyCard(
                                    title: "This Month",
                                    earnings: summaryData.formattedThisMonthEarnings,
                                    delta: summaryData.thisMonthDelta,
                                    deltaPositive: summaryData.thisMonthDeltaPositive,
                                    color: .purple
                                )
                                
                                MonthlyCard(
                                    title: "Last Month",
                                    earnings: summaryData.formattedLastMonthEarnings,
                                    delta: nil,
                                    deltaPositive: nil,
                                    color: .pink
                                )
                            }
                            .opacity(cardAppearances[3] ? 1 : 0)
                            .offset(y: cardAppearances[3] ? 0 : 15)
                        }
                        
                        // Today's detailed metrics if available
                        if let clicks = summaryData.todayClicks,
                           let pageViews = summaryData.todayPageViews,
                           let impressions = summaryData.todayImpressions {
                            
                            VStack(spacing: 8) {
                                SectionHeader(title: "Today's Stats", icon: "chart.bar.fill")
                                
                                VStack(spacing: 4) {
                                    MetricRow(icon: "cursorarrow.click", label: "Clicks", value: clicks, color: .blue)
                                    MetricRow(icon: "doc.text", label: "Page Views", value: pageViews, color: .orange)
                                    MetricRow(icon: "eye", label: "Impressions", value: impressions, color: .cyan)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                        
                        // Status footer
                        StatusFooter(
                            lastUpdated: dataManager.lastUpdated,
                            isConnected: dataManager.isConnected,
                            connectionStatus: dataManager.connectionStatus
                        )
                        
                    } else {
                        // Enhanced no data state
                        NoDataView(onRefresh: {
                            dataManager.refreshData()
                        })
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
            }
            .navigationTitle("AdRadar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Button {
                            WKInterfaceDevice.current().play(.click)
                            dataManager.refreshData()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.footnote)
                                .fontWeight(.medium)
                        }
                        
                        Button {
                            WKInterfaceDevice.current().play(.click)
                            dataManager.loadTestDataManually()
                        } label: {
                            Image(systemName: "testtube.2")
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .onAppear {
                // Animate cards in sequence
                for i in 0..<cardAppearances.count {
                    withAnimation(.easeOut(duration: 0.5).delay(Double(i) * 0.1)) {
                        cardAppearances[i] = true
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Components

struct HeroTodayCard: View {
    let earnings: String
    let delta: String?
    let deltaPositive: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with icon and title
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.green.opacity(0.2),
                                    Color.green.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Today So Far")
                        .font(.watchBody)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("vs yesterday")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Main earnings value
            Text(earnings)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            // Delta indicator
            if let delta = delta, let positive = deltaPositive {
                HStack(spacing: 4) {
                    Image(systemName: positive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(positive ? .green : .red)
                    
                    Text(delta)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(positive ? .green : .red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background((positive ? Color.green : Color.red).opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.green.opacity(0.08), location: 0),
                    .init(color: Color.green.opacity(0.04), location: 0.5),
                    .init(color: Color.green.opacity(0.02), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.green.opacity(0.1), lineWidth: 0.5)
        )
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

struct CompactEarningsCard: View {
    let title: String
    let earnings: String
    let delta: String?
    let deltaPositive: Bool?
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Image(systemName: title.contains("Yesterday") ? "calendar.badge.clock" : "calendar.badge.plus")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20, height: 20)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let delta = delta, let positive = deltaPositive {
                    HStack(spacing: 2) {
                        Image(systemName: positive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(positive ? .green : .red)
                        
                        Text(delta)
                            .font(.system(size: 10))
                            .foregroundColor(positive ? .green : .red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
            
            Spacer()
            
            // Earnings value
            Text(earnings)
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct MonthlyCard: View {
    let title: String
    let earnings: String
    let delta: String?
    let deltaPositive: Bool?
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with icon
            HStack {
                Image(systemName: title.contains("This") ? "calendar" : "calendar.badge.minus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 16, height: 16)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            // Title
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            // Earnings
            Text(earnings)
                .font(.system(size: 12))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            
            // Delta
            if let delta = delta, let positive = deltaPositive {
                HStack(spacing: 2) {
                    Image(systemName: positive ? "arrow.up" : "arrow.down")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(positive ? .green : .red)
                    
                    Text(delta)
                        .font(.system(size: 7))
                        .foregroundColor(positive ? .green : .red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            } else {
                Text(" ")
                    .font(.system(size: 7))
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: color.opacity(0.08), location: 0),
                    .init(color: color.opacity(0.04), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(10)
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
                .frame(width: 16, height: 16)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 10))
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

struct StatusFooter: View {
    let lastUpdated: Date?
    let isConnected: Bool
    let connectionStatus: String
    
    var body: some View {
        VStack(spacing: 4) {
            // Connection status
            HStack(spacing: 4) {
                Circle()
                    .fill(isConnected ? .green : .red)
                    .frame(width: 4, height: 4)
                
                Text(connectionStatus)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // Last updated
            if let lastUpdated = lastUpdated {
                Text("Updated \(lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.top, 8)
    }
}

struct NoDataView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(0.2),
                                Color.accentColor.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "iphone.and.arrow.forward")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 4) {
                Text("No Data Available")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Open AdRadar on your iPhone to sync the latest data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            Button("Refresh") {
                onRefresh()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 20)
    }
}

#Preview {
    ContentView()
}
