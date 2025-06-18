import Foundation
import SwiftUI

struct StreakDayData: Identifiable {
    let id = UUID()
    let date: Date
    let earnings: Double
    let clicks: Int
    let impressions: Int
    let impressionCTR: Double
    let pageViews: Int
    let costPerClick: Double
    let requests: Int
    let delta: Double?
    let deltaPositive: Bool?
}

@MainActor
class StreakViewModel: ObservableObject {
    @Published var streakData: [StreakDayData] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var hasLoaded: Bool = false
    
    var accessToken: String?
    private var accountID: String?
    var authViewModel: AuthViewModel?
    private var fetchTask: Task<Void, Never>?
    
    init(accessToken: String?, authViewModel: AuthViewModel? = nil) {
        self.accessToken = accessToken
        self.authViewModel = authViewModel
        if accessToken != nil {
            fetchTask = Task { await fetchStreakData() }
        }
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    func fetchStreakData() async {
        // Cancel any existing task
        fetchTask?.cancel()
        
        // Create new task
        fetchTask = Task {
            guard let token = accessToken else { return }
            isLoading = true
            error = nil
            
            // Fetch account ID with retry logic
            var retryCount = 0
            let maxRetries = 3
            var currentToken = token
            
            while retryCount < maxRetries {
                do {
                    try Task.checkCancellation()
                    
                    let accountResult = await AdSenseAPI.fetchAccountID(accessToken: currentToken)
                    switch accountResult {
                    case .success(let accountID):
                        self.accountID = accountID
                        break
                    case .failure(let err):
                        switch err {
                        case .unauthorized:
                            if let authVM = authViewModel {
                                let refreshed = await authVM.refreshTokenIfNeeded()
                                if refreshed {
                                    currentToken = authVM.accessToken ?? currentToken
                                    retryCount += 1
                                    continue
                                }
                            }
                            self.error = "Session expired. Please sign in again."
                            self.isLoading = false
                            return
                        case .requestFailed(let message):
                            if message.contains("cancelled") {
                                return // Task was cancelled, exit gracefully
                            }
                            self.error = "Failed to get AdSense account: \(message)"
                            retryCount += 1
                            continue
                        default:
                            self.error = "Failed to get AdSense account: \(err)"
                            self.isLoading = false
                            return
                        }
                    }
                    
                    guard let accountID = self.accountID else {
                        self.error = "No AdSense account found."
                        self.isLoading = false
                        return
                    }
                    
                    // Calculate date range for last 8 days
                    let calendar = Calendar.current
                    let today = Date()
                    let startDate = calendar.date(byAdding: .day, value: -7, to: today)!
                    
                    // Fetch metrics for each day
                    var newStreakData: [StreakDayData] = []
                    var previousEarnings: Double?
                    
                    for dayOffset in 0...7 {
                        try Task.checkCancellation()
                        
                        let currentDate = calendar.date(byAdding: .day, value: dayOffset, to: startDate)!
                        let result = await AdSenseAPI.shared.fetchMetricsForRange(
                            accountID: accountID,
                            accessToken: currentToken,
                            startDate: currentDate,
                            endDate: currentDate
                        )
                        
                        switch result {
                        case .success(let metrics):
                            let earnings = Double(metrics.estimatedEarnings) ?? 0
                            let clicks = Int(metrics.clicks) ?? 0
                            let impressions = Int(metrics.impressions) ?? 0
                            let impressionCTR = Double(metrics.impressionsCTR) ?? 0
                            let pageViews = Int(metrics.pageViews) ?? 0
                            let costPerClick = Double(metrics.costPerClick) ?? 0
                            let requests = Int(metrics.requests) ?? 0
                            
                            // Calculate delta if we have previous earnings
                            var delta: Double?
                            var deltaPositive: Bool?
                            if let prevEarnings = previousEarnings {
                                delta = earnings - prevEarnings
                                deltaPositive = delta! >= 0
                            }
                            
                            let dayData = StreakDayData(
                                date: currentDate,
                                earnings: earnings,
                                clicks: clicks,
                                impressions: impressions,
                                impressionCTR: impressionCTR,
                                pageViews: pageViews,
                                costPerClick: costPerClick,
                                requests: requests,
                                delta: delta,
                                deltaPositive: deltaPositive
                            )
                            
                            newStreakData.append(dayData)
                            previousEarnings = earnings
                            
                        case .failure(let error):
                            if error.localizedDescription.contains("cancelled") {
                                return // Task was cancelled, exit gracefully
                            }
                            self.error = "Failed to fetch data for \(currentDate.formatted(date: .abbreviated, time: .omitted)): \(error)"
                            self.isLoading = false
                            return
                        }
                    }
                    
                    self.streakData = newStreakData.sorted { $0.date > $1.date }
                    self.isLoading = false
                    self.hasLoaded = true
                    return
                    
                } catch {
                    if error is CancellationError {
                        return // Task was cancelled, exit gracefully
                    }
                    self.error = "An unexpected error occurred: \(error.localizedDescription)"
                    retryCount += 1
                }
            }
            
            self.isLoading = false
        }
    }
    
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "R "
        formatter.currencyGroupingSeparator = " "
        formatter.currencyDecimalSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "R 0,00"
    }
    
    func formatPercentage(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }
} 