import Foundation

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
    
    var formattedImpressionsCTR: String {
        guard let value = Double(impressionsCTR) else { return impressionsCTR }
        return String(format: "%.2f%%", value * 100)
    }
    var formattedPageViewsCTR: String {
        guard let value = Double(pageViewsCTR) else { return pageViewsCTR }
        return String(format: "%.2f%%", value * 100)
    }
    var formattedCostPerClick: String {
        guard let value = Double(costPerClick) else { return costPerClick }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "R " // Change to "$" or use locale if needed
        return formatter.string(from: NSNumber(value: value)) ?? costPerClick
    }
    var formattedEstimatedEarnings: String {
        guard let value = Double(estimatedEarnings) else { return estimatedEarnings }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "R " // Change to "$" or use locale if needed
        return formatter.string(from: NSNumber(value: value)) ?? estimatedEarnings
    }
    
    enum CodingKeys: String, CodingKey {
        case estimatedEarnings = "ESTIMATED_EARNINGS"
        case clicks = "CLICKS"
        case pageViews = "PAGE_VIEWS"
        case impressions = "IMPRESSIONS"
        case adRequests = "AD_REQUESTS"
        case matchedAdRequests = "MATCHED_AD_REQUESTS"
        case costPerClick = "COST_PER_CLICK"
        case impressionsCTR = "IMPRESSIONS_CTR"
        case impressionsRPM = "IMPRESSIONS_RPM"
        case pageViewsCTR = "PAGE_VIEWS_CTR"
        case pageViewsRPM = "PAGE_VIEWS_RPM"
    }
} 