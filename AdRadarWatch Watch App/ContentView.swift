//
//  ContentView.swift
//  AdRadarWatch Watch App
//
//  Created by Guilio Del Fava on 2025/06/24.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @StateObject private var connectivityService = WatchConnectivityService.shared
    @State private var selectedPage: Int = 0
    @State private var showDetailView = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedPage) {
                // Main Summary Page
                MainSummaryView()
                    .tag(0)
                
                // Recent Performance Page
                RecentPerformanceView()
                    .tag(1)
                
                // Monthly Overview Page
                MonthlyOverviewView()
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .navigationTitle("AdRadar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        connectivityService.refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.accentColor)
                    }
                    .disabled(connectivityService.isLoading)
                }
            }
        }
        .environmentObject(connectivityService)
    }
}

struct MainSummaryView: View {
    @EnvironmentObject var connectivityService: WatchConnectivityService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if connectivityService.isLoading {
                    WatchLoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = connectivityService.errorMessage {
                    WatchErrorView(message: errorMessage) {
                        connectivityService.refreshData()
                    }
                } else if let data = connectivityService.summaryData {
                    // Hero Card - Today's Performance
                    WatchHeroCard(
                        title: "Today So Far",
                        value: data.todayEarnings,
                        subtitle: "vs yesterday",
                        delta: data.todayDelta,
                        deltaPositive: data.todayDeltaPositive
                    )
                    
                    // Today's Stats
                    if data.todayClicks != nil || data.todayPageViews != nil {
                        WatchMetricsCard(
                            clicks: data.todayClicks,
                            pageViews: data.todayPageViews,
                            impressions: data.todayImpressions
                        )
                    }
                    
                    // Last Update Time
                    if let lastUpdate = connectivityService.lastUpdateTime {
                        Text("Updated \(formatRelativeTime(lastUpdate))")
                            .font(.custom("Sora-Light", size: 9))
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                } else {
                    WatchNoDataView {
                        connectivityService.refreshData()
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}

struct RecentPerformanceView: View {
    @EnvironmentObject var connectivityService: WatchConnectivityService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let data = connectivityService.summaryData {
                    Text("Recent")
                        .font(.custom("Sora-SemiBold", size: 16))
                        .foregroundColor(.primary)
                        .padding(.bottom, 4)
                    
                    WatchSummaryCard(
                        title: "Yesterday",
                        value: data.yesterdayEarnings,
                        subtitle: "vs same day last week",
                        delta: data.yesterdayDelta,
                        deltaPositive: data.yesterdayDeltaPositive,
                        icon: "calendar.badge.clock",
                        color: .orange
                    )
                    
                    WatchSummaryCard(
                        title: "Last 7 Days",
                        value: data.last7DaysEarnings,
                        subtitle: "vs previous 7 days",
                        delta: data.last7DaysDelta,
                        deltaPositive: data.last7DaysDeltaPositive,
                        icon: "calendar.badge.plus",
                        color: .blue
                    )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.custom("Sora-SemiBold", size: 20))
                            .foregroundColor(.secondary)
                        
                        Text("No recent data")
                            .font(.custom("Sora-Regular", size: 10))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}

struct MonthlyOverviewView: View {
    @EnvironmentObject var connectivityService: WatchConnectivityService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                if let data = connectivityService.summaryData {
                    Text("Monthly")
                        .font(.custom("Sora-SemiBold", size: 16))
                        .foregroundColor(.primary)
                        .padding(.bottom, 4)
                    
                    WatchSummaryCard(
                        title: "This Month",
                        value: data.thisMonthEarnings,
                        subtitle: "vs same day last month",
                        delta: data.thisMonthDelta,
                        deltaPositive: data.thisMonthDeltaPositive,
                        icon: "calendar",
                        color: .purple
                    )
                    
                    WatchSummaryCard(
                        title: "Last Month",
                        value: data.lastMonthEarnings,
                        subtitle: "vs previous month",
                        delta: nil, // Usually no delta for completed months
                        deltaPositive: nil,
                        icon: "calendar.badge.minus",
                        color: .pink
                    )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.fill")
                            .font(.custom("Sora-SemiBold", size: 20))
                            .foregroundColor(.secondary)
                        
                        Text("No monthly data")
                            .font(.custom("Sora-Regular", size: 10))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
    }
}

// MARK: - Helper Functions
private func formatRelativeTime(_ date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: date, relativeTo: Date())
}

#Preview {
    ContentView()
}
