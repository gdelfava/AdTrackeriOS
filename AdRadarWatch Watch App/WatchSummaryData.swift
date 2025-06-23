import Foundation

// Simplified data structure for Apple Watch
struct WatchSummaryData: Codable {
    let todayEarnings: String
    let yesterdayEarnings: String
    let last7DaysEarnings: String
    let thisMonthEarnings: String
    let lastMonthEarnings: String
    
    // Delta information for trends
    let todayDelta: String?
    let todayDeltaPositive: Bool?
    let yesterdayDelta: String?
    let yesterdayDeltaPositive: Bool?
    let last7DaysDelta: String?
    let last7DaysDeltaPositive: Bool?
    let thisMonthDelta: String?
    let thisMonthDeltaPositive: Bool?
    
    // Additional key metrics for today
    let todayClicks: String?
    let todayPageViews: String?
    let todayImpressions: String?
    
    // Last update timestamp
    let lastUpdated: Date
    
    // Main initializer
    init(todayEarnings: String, yesterdayEarnings: String, last7DaysEarnings: String, 
         thisMonthEarnings: String, lastMonthEarnings: String,
         todayDelta: String?, todayDeltaPositive: Bool?,
         yesterdayDelta: String?, yesterdayDeltaPositive: Bool?,
         last7DaysDelta: String?, last7DaysDeltaPositive: Bool?,
         thisMonthDelta: String?, thisMonthDeltaPositive: Bool?,
         todayClicks: String?, todayPageViews: String?, todayImpressions: String?,
         lastUpdated: Date) {
        
        self.todayEarnings = todayEarnings
        self.yesterdayEarnings = yesterdayEarnings
        self.last7DaysEarnings = last7DaysEarnings
        self.thisMonthEarnings = thisMonthEarnings
        self.lastMonthEarnings = lastMonthEarnings
        
        self.todayDelta = todayDelta
        self.todayDeltaPositive = todayDeltaPositive
        self.yesterdayDelta = yesterdayDelta
        self.yesterdayDeltaPositive = yesterdayDeltaPositive
        self.last7DaysDelta = last7DaysDelta
        self.last7DaysDeltaPositive = last7DaysDeltaPositive
        self.thisMonthDelta = thisMonthDelta
        self.thisMonthDeltaPositive = thisMonthDeltaPositive
        
        self.todayClicks = todayClicks
        self.todayPageViews = todayPageViews
        self.todayImpressions = todayImpressions
        
        self.lastUpdated = lastUpdated
    }
    
    // Formatting helpers
    var formattedTodayEarnings: String {
        return formatCurrency(todayEarnings)
    }
    
    var formattedYesterdayEarnings: String {
        return formatCurrency(yesterdayEarnings)
    }
    
    var formattedLast7DaysEarnings: String {
        return formatCurrency(last7DaysEarnings)
    }
    
    var formattedThisMonthEarnings: String {
        return formatCurrency(thisMonthEarnings)
    }
    
    var formattedLastMonthEarnings: String {
        return formatCurrency(lastMonthEarnings)
    }
    
    private func formatCurrency(_ value: String) -> String {
        // If value is already formatted (contains "R "), just return it
        if value.contains("R ") {
            return value
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "R "
        formatter.currencyGroupingSeparator = " "
        formatter.currencyDecimalSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        
        // Handle different input formats
        let cleanValue = value
            .replacingOccurrences(of: "R ", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")
        
        if let doubleValue = Double(cleanValue) {
            return formatter.string(from: NSNumber(value: doubleValue)) ?? "R 0,00"
        }
        return "R 0,00"
    }
} 