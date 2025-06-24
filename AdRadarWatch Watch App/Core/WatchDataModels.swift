import Foundation
import WatchConnectivity

// MARK: - Summary Data Model
struct AdSenseSummaryData: Codable {
    let today: String
    let yesterday: String
    let last7Days: String
    let thisMonth: String
    let lastMonth: String
    let lifetime: String
    
    // Delta values and positivity for each card
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

// MARK: - Day Metrics Model
struct AdSenseDayMetrics: Codable {
    let estimatedEarnings: String
    let clicks: String
    let pageViews: String
    let impressions: String
    let adRequests: String
    let matchedAdRequests: String
    let costPerClick: String
    let impressionsCTR: String
    let impressionsRPM: String
    let pageViewsCTR: String
    let pageViewsRPM: String
    
    // For backward compatibility with the UI
    var estimatedGrossRevenue: String { estimatedEarnings }
    var requests: String { pageViews }
    var impressionCTR: String { impressionsCTR }
    var matchedRequests: String { matchedAdRequests }
}

// MARK: - Watch-specific Models
struct WatchSummaryData {
    let todayEarnings: String
    let yesterdayEarnings: String
    let last7DaysEarnings: String
    let thisMonthEarnings: String
    let lastMonthEarnings: String
    
    let todayDelta: String?
    let todayDeltaPositive: Bool?
    let yesterdayDelta: String?
    let yesterdayDeltaPositive: Bool?
    let last7DaysDelta: String?
    let last7DaysDeltaPositive: Bool?
    let thisMonthDelta: String?
    let thisMonthDeltaPositive: Bool?
    
    let todayClicks: String?
    let todayPageViews: String?
    let todayImpressions: String?
    
    let lastUpdated: Date
    
    init(from context: [String: Any]) {
        self.todayEarnings = context["todayEarnings"] as? String ?? "R 0,00"
        self.yesterdayEarnings = context["yesterdayEarnings"] as? String ?? "R 0,00"
        self.last7DaysEarnings = context["last7DaysEarnings"] as? String ?? "R 0,00"
        self.thisMonthEarnings = context["thisMonthEarnings"] as? String ?? "R 0,00"
        self.lastMonthEarnings = context["lastMonthEarnings"] as? String ?? "R 0,00"
        
        self.todayDelta = context["todayDelta"] as? String
        self.todayDeltaPositive = context["todayDeltaPositive"] as? Bool
        self.yesterdayDelta = context["yesterdayDelta"] as? String
        self.yesterdayDeltaPositive = context["yesterdayDeltaPositive"] as? Bool
        self.last7DaysDelta = context["last7DaysDelta"] as? String
        self.last7DaysDeltaPositive = context["last7DaysDeltaPositive"] as? Bool
        self.thisMonthDelta = context["thisMonthDelta"] as? String
        self.thisMonthDeltaPositive = context["thisMonthDeltaPositive"] as? Bool
        
        self.todayClicks = context["todayClicks"] as? String
        self.todayPageViews = context["todayPageViews"] as? String
        self.todayImpressions = context["todayImpressions"] as? String
        
        if let timestamp = context["lastUpdated"] as? TimeInterval {
            self.lastUpdated = Date(timeIntervalSince1970: timestamp)
        } else {
            self.lastUpdated = Date()
        }
    }
} 