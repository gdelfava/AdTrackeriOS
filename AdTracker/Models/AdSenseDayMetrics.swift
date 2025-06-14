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