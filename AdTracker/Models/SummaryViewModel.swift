import Foundation
import Combine
import Network
import GoogleSignIn

@MainActor
class SummaryViewModel: ObservableObject {
    @Published var summaryData: AdSenseSummaryData? = nil
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var last7DaysData: AdSenseSummaryData? = nil
    @Published var last30DaysData: AdSenseSummaryData? = nil
    @Published var thisMonthData: AdSenseSummaryData? = nil
    @Published var lastMonthData: AdSenseSummaryData? = nil
    @Published var isOffline: Bool = false
    @Published var showOfflineToast: Bool = false
    @Published var showNetworkErrorModal: Bool = false
    @Published var hasLoaded: Bool = false
    @Published var selectedDay: Date? = nil
    @Published var selectedDayMetrics: AdSenseDayMetrics? = nil
    @Published var showDayMetricsSheet: Bool = false
    @Published var errorMessage: String? = nil
    @Published var lastUpdateTime: Date? = nil
    
    var accessToken: String?
    private var accountID: String?
    var authViewModel: AuthViewModel?
    private var fetchTask: Task<Void, Never>?
    
    init(accessToken: String?, authViewModel: AuthViewModel? = nil) {
        self.accessToken = accessToken
        self.authViewModel = authViewModel
        // Load last update time from UserDefaults
        if let defaults = UserDefaults(suiteName: AdSenseAPI.appGroupID) {
            self.lastUpdateTime = defaults.object(forKey: "summaryLastUpdate") as? Date
        }
        if accessToken != nil {
            fetchTask = Task { await fetchSummary() }
        }
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    private func formatCurrency(_ value: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "R "
        formatter.currencyGroupingSeparator = " "
        formatter.currencyDecimalSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        if let doubleValue = Double(value.replacingOccurrences(of: ",", with: ".")) {
            return formatter.string(from: NSNumber(value: doubleValue)) ?? "R 0,00"
        }
        return "R 0,00"
    }

    private func calculateDelta(current: String, previous: String) -> (String, Bool)? {
        guard let currentValue = Double(current.replacingOccurrences(of: ",", with: ".")),
              let previousValue = Double(previous.replacingOccurrences(of: ",", with: ".")),
              previousValue != 0 else { return nil }
        
        // Calculate currency difference
        let diff = currentValue - previousValue
        let isPositive = diff >= 0
        
        // Format currency difference
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "R "
        formatter.currencyGroupingSeparator = " "
        formatter.currencyDecimalSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let formattedDiff = formatter.string(from: NSNumber(value: abs(diff))) ?? "R 0,00"
        
        // Calculate and format percentage
        let percent = ((currentValue - previousValue) / abs(previousValue)) * 100
        let formattedPercent = String(format: "%+.1f%%", percent)
        
        // Combine both values
        let sign = isPositive ? "+" : "-"
        let combined = "\(sign)\(formattedDiff) (\(formattedPercent))"
        
        return (combined, isPositive)
    }
    
    private func sleep(seconds: Double) async {
        let duration = UInt64(seconds * 1_000_000_000)
        try? await Task.sleep(nanoseconds: duration)
    }
    
    func fetchSummary() async {
        if hasLoaded { return }
        fetchTask?.cancel()
        fetchTask = Task {
            if !NetworkMonitor.shared.isConnected {
                self.isOffline = true
                self.showOfflineToast = true
                self.showNetworkErrorModal = true
                // Auto-hide after 2 seconds
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    self.showOfflineToast = false
                }
                self.error = "No internet connection."
                self.isLoading = false
                return
            } else {
                self.isOffline = false
                self.showNetworkErrorModal = false
            }

            let maxRetries = 3
            var retryCount = 0
            var currentToken = accessToken ?? ""

            while retryCount < maxRetries {
                self.isLoading = true
                self.error = nil
                
                // Fetch account ID
                let accountResult = await AdSenseAPI.fetchAccountID(accessToken: currentToken)
                switch accountResult {
                case .success(let accountID):
                    self.accountID = accountID
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
                        self.error = "Failed to get AdSense account: \(message)"
                        self.isLoading = false
                        return
                    case .noAccountID:
                        self.error = "No AdSense account found."
                        self.isLoading = false
                        return
                    case .invalidURL:
                        self.error = "Invalid API URL configuration."
                        self.isLoading = false
                        return
                    case .invalidResponse:
                        self.error = "Invalid response from AdSense API."
                        self.isLoading = false
                        return
                    case .decodingError(let message):
                        self.error = "Failed to decode response: \(message)"
                        self.isLoading = false
                        return
                    }
                }
                
                guard let accountID = self.accountID else {
                    self.error = "No AdSense account found."
                    self.isLoading = false
                    return
                }
                
                let calendar = Calendar.current
                let today = Date()
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
                let last7DaysStart = calendar.date(byAdding: .day, value: -6, to: today)!
                let prev7DaysStart = calendar.date(byAdding: .day, value: -13, to: today)!
                let prev7DaysEnd = calendar.date(byAdding: .day, value: -7, to: today)!
                let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
                let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
                let lastMonthEnd = calendar.date(byAdding: .day, value: -1, to: thisMonthStart)!
                let prevMonthStart = calendar.date(byAdding: .month, value: -1, to: lastMonthStart)!
                let prevMonthEnd = calendar.date(byAdding: .day, value: -1, to: lastMonthStart)!
                let threeYearsAgo = calendar.date(byAdding: .year, value: -3, to: today)!
                
                // Create a local copy of the token for concurrent operations
                let token = currentToken
                
                // Fetch all summary data in parallel using the local token copy
                async let todayResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: today, endDate: today)
                async let yesterdayResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: yesterday, endDate: yesterday)
                async let last7DaysResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: last7DaysStart, endDate: today)
                async let prev7DaysResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: prev7DaysStart, endDate: prev7DaysEnd)
                async let thisMonthResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: thisMonthStart, endDate: today)
                async let lastMonthResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: lastMonthStart, endDate: lastMonthEnd)
                async let prevMonthResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: prevMonthStart, endDate: prevMonthEnd)
                async let lastThreeYearsResult = AdSenseAPI.shared.fetchSummaryData(accountID: accountID, accessToken: token, startDate: threeYearsAgo, endDate: today)
                
                let (todayData, yesterdayData, last7DaysData, prev7DaysData, thisMonthData, lastMonthData, prevMonthData, lastThreeYearsData) = await (
                    todayResult, yesterdayResult, last7DaysResult, prev7DaysResult, thisMonthResult, lastMonthResult, prevMonthResult, lastThreeYearsResult
                )
                // Format and calculate deltas
                let todayValue = (try? todayData.get().last7Days) ?? "0.00"
                let yesterdayValue = (try? yesterdayData.get().last7Days) ?? "0.00"
                let last7Value = (try? last7DaysData.get().last7Days) ?? "0.00"
                let prev7Value = (try? prev7DaysData.get().last7Days) ?? "0.00"
                let thisMonthValue = (try? thisMonthData.get().last7Days) ?? "0.00"
                let lastMonthValue = (try? lastMonthData.get().last7Days) ?? "0.00"
                let prevMonthValue = (try? prevMonthData.get().last7Days) ?? "0.00"
                let lastThreeYearsValue = (try? lastThreeYearsData.get().last7Days) ?? "0.00"
                let summary = AdSenseSummaryData(
                    today: formatCurrency(todayValue),
                    yesterday: formatCurrency(yesterdayValue),
                    last7Days: formatCurrency(last7Value),
                    thisMonth: formatCurrency(thisMonthValue),
                    lastMonth: formatCurrency(lastMonthValue),
                    lifetime: formatCurrency(lastThreeYearsValue),
                    todayDelta: calculateDelta(current: todayValue, previous: yesterdayValue)?.0,
                    todayDeltaPositive: calculateDelta(current: todayValue, previous: yesterdayValue)?.1,
                    yesterdayDelta: calculateDelta(current: yesterdayValue, previous: (try? yesterdayData.get().last7Days) ?? "0.00")?.0, // Could use last week's same day if available
                    yesterdayDeltaPositive: calculateDelta(current: yesterdayValue, previous: (try? yesterdayData.get().last7Days) ?? "0.00")?.1,
                    last7DaysDelta: calculateDelta(current: last7Value, previous: prev7Value)?.0,
                    last7DaysDeltaPositive: calculateDelta(current: last7Value, previous: prev7Value)?.1,
                    thisMonthDelta: calculateDelta(current: thisMonthValue, previous: lastMonthValue)?.0,
                    thisMonthDeltaPositive: calculateDelta(current: thisMonthValue, previous: lastMonthValue)?.1,
                    lastMonthDelta: calculateDelta(current: lastMonthValue, previous: prevMonthValue)?.0,
                    lastMonthDeltaPositive: calculateDelta(current: lastMonthValue, previous: prevMonthValue)?.1
                )
                self.summaryData = summary
                AdSenseAPI.shared.saveSummaryToSharedContainer(summary)
                // Save the last update time as well
                if let defaults = UserDefaults(suiteName: AdSenseAPI.appGroupID) {
                    let now = Date()
                    defaults.set(now, forKey: "summaryLastUpdate")
                    self.lastUpdateTime = now
                }
                self.hasLoaded = true
                self.isLoading = false
                return
            }
            self.error = "Failed to fetch summary data after multiple attempts."
            self.isLoading = false
        }
    }
    
    enum MetricsCardType {
        case today, yesterday, last7Days, thisMonth, lastMonth
    }
    
    /// Fetches and stores detailed metrics for a given card type (date range)
    func fetchMetrics(forCard card: MetricsCardType) async {
        print("[SummaryViewModel] Starting fetchMetrics for card: \(card)")
        errorMessage = nil
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("[SummaryViewModel] No current user found")
            errorMessage = "Not signed in."
            return
        }
        print("[SummaryViewModel] Found current user, refreshing tokens...")
        await withCheckedContinuation { continuation in
            user.refreshTokensIfNeeded { refreshedUser, error in
                if let error = error {
                    print("[SummaryViewModel] Token refresh failed: \(error)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Token refresh failed: \(error.localizedDescription)"
                        continuation.resume()
                    }
                    return
                }
                guard let refreshedUser = refreshedUser else {
                    print("[SummaryViewModel] No user after token refresh")
                    DispatchQueue.main.async {
                        self.errorMessage = "No user after token refresh."
                        continuation.resume()
                    }
                    return
                }
                print("[SummaryViewModel] Successfully refreshed tokens")
                let accessToken = refreshedUser.accessToken.tokenString
                let accountID = self.accountID ?? ""
                print("[SummaryViewModel] Using accountID: \(accountID)")
                let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let startDate: Date
                let endDate: Date
                switch card {
                case .today:
                    startDate = today
                    endDate = today
                case .yesterday:
                    startDate = calendar.date(byAdding: .day, value: -1, to: today) ?? today
                    endDate = startDate
                case .last7Days:
                    startDate = calendar.date(byAdding: .day, value: -6, to: today) ?? today
                    endDate = today
                case .thisMonth:
                    let comps = calendar.dateComponents([.year, .month], from: today)
                    startDate = calendar.date(from: comps) ?? today
                    endDate = today
                case .lastMonth:
                    let comps = calendar.dateComponents([.year, .month], from: today)
                    let firstOfThisMonth = calendar.date(from: comps) ?? today
                    let lastDayOfLastMonth = calendar.date(byAdding: .day, value: -1, to: firstOfThisMonth) ?? today
                    let compsLastMonth = calendar.dateComponents([.year, .month], from: lastDayOfLastMonth)
                    startDate = calendar.date(from: compsLastMonth) ?? today
                    endDate = lastDayOfLastMonth
                }
                Task {
                    let result = await AdSenseAPI.shared.fetchMetricsForRange(accountID: accountID, accessToken: accessToken, startDate: startDate, endDate: endDate)
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let metrics):
                            self.selectedDayMetrics = metrics
                            self.showDayMetricsSheet = true
                        case .failure(let error):
                            self.errorMessage = "Failed to load metrics: \(error.localizedDescription)"
                        }
                        continuation.resume()
                    }
                }
            }
        }
    }
} 
