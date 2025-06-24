import Foundation
import Combine

struct PaymentsData {
    let unpaidEarnings: String
    let unpaidEarningsValue: Double // Raw value for calculations
    let previousPaymentDate: String
    let previousPaymentAmount: String
    let currentMonthEarnings: String
    let currentMonthEarningsValue: Double // Raw value for progress calculations
}

class PaymentsViewModel: ObservableObject {
    @Published var paymentsData: PaymentsData? = nil
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var hasLoaded: Bool = false
    @Published var lastUpdateTime: Date? = nil
    @Published var showEmptyState: Bool = false
    @Published var emptyStateMessage: String? = nil
    
    var accessToken: String?
    var authViewModel: AuthViewModel?
    private var accountID: String?
    private var currentTask: Task<Void, Never>?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
        // Remove automatic fetching - only fetch when explicitly called
    }
    
    @MainActor
    func fetchPayments() async {
        guard let currentToken = accessToken else { 
            self.error = "No access token available. Please sign in again."
            return 
        }
        
        // Cancel any existing task to prevent conflicts
        currentTask?.cancel()
        
        // Create new task
        currentTask = Task {
            await performFetchPayments(with: currentToken)
        }
        
        await currentTask?.value
    }
    
    @MainActor
    private func performFetchPayments(with token: String) async {
        // Check if task was cancelled before starting
        if Task.isCancelled {
            return
        }
        
        self.isLoading = true
        self.error = nil
        self.showEmptyState = false
        self.emptyStateMessage = nil
        
        let maxRetries = 2
        var retryCount = 0
        var workingToken = token
        
        while retryCount < maxRetries && !Task.isCancelled {
            // 1. Fetch account ID
            let accountResult = await AdSenseAPI.fetchAccountID(accessToken: workingToken)
            
            // Check for cancellation after each async operation
            if Task.isCancelled {
                self.isLoading = false
                return
            }
            
            switch accountResult {
            case .success(let accountID):
                self.accountID = accountID
            case .failure(let err):
                switch err {
                case .unauthorized:
                    if let authVM = authViewModel {
                        let refreshed = await authVM.refreshTokenIfNeeded()
                        if refreshed && !Task.isCancelled {
                            workingToken = authVM.accessToken ?? workingToken
                            retryCount += 1
                            continue
                        }
                    }
                    if !Task.isCancelled {
                        self.error = "Session expired. Please sign in again."
                    }
                    self.isLoading = false
                    return
                case .noAccountID:
                    if !Task.isCancelled {
                        self.error = "No AdSense account found."
                    }
                    self.isLoading = false
                    return
                case .requestFailed(let message):
                    // Handle cancellation more gracefully
                    if message.contains("Request was cancelled") || Task.isCancelled {
                        // Silently ignore cancellation errors during refresh
                        self.isLoading = false
                        return
                    }
                    // Check for specific empty state conditions
                    if message.contains("FAILED_PRECONDITION|") {
                        let actualMessage = String(message.dropFirst("FAILED_PRECONDITION|".count))
                        if !Task.isCancelled {
                            self.showEmptyState = true
                            self.emptyStateMessage = actualMessage
                            self.error = nil
                        }
                        self.isLoading = false
                        return
                    }
                    if !Task.isCancelled {
                        self.error = "Failed to get AdSense account: \(message)"
                    }
                    self.isLoading = false
                    return
                case .invalidURL:
                    if !Task.isCancelled {
                        self.error = "Invalid API URL configuration."
                    }
                    self.isLoading = false
                    return
                case .invalidResponse:
                    if !Task.isCancelled {
                        self.error = "Invalid response from AdSense API."
                    }
                    self.isLoading = false
                    return
                case .decodingError(let message):
                    if !Task.isCancelled {
                        self.error = "Data parsing error: \(message)"
                    }
                    self.isLoading = false
                    return
                }
            }
            
            guard let accountID = self.accountID, !Task.isCancelled else {
                if !Task.isCancelled {
                    self.error = "No AdSense account found."
                }
                self.isLoading = false
                return
            }
            
            // 2. Fetch unpaid earnings, previous payment, and current month earnings in parallel
            // Capture the token value to avoid concurrency warnings
            let currentWorkingToken = workingToken
            
            // Calculate current month date range
            let calendar = Calendar.current
            let now = Date()
            let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let currentMonthStartStr = dateFormatter.string(from: currentMonthStart)
            let currentMonthEndStr = dateFormatter.string(from: now)
            
            async let unpaidResult = AdSenseAPI.shared.fetchUnpaidEarnings(accessToken: currentWorkingToken, accountID: accountID)
            async let prevPaymentResult = AdSenseAPI.shared.fetchPreviousPayment(accessToken: currentWorkingToken, accountID: accountID)
            async let currentMonthResult = AdSenseAPI.shared.fetchReport(accessToken: currentWorkingToken, accountID: accountID, startDate: currentMonthStartStr, endDate: currentMonthEndStr)
            
            let unpaid = await unpaidResult
            let prev = await prevPaymentResult
            let currentMonth = await currentMonthResult
            
            // Check for cancellation after async operations
            if Task.isCancelled {
                self.isLoading = false
                return
            }
            
            // Check for 401 errors in any request
            var needsRetry = false
            if case .failure(let error) = unpaid, case .unauthorized = error {
                needsRetry = true
            }
            if case .failure(let error) = prev, case .unauthorized = error {
                needsRetry = true
            }
            if case .failure(let error) = currentMonth, case .unauthorized = error {
                needsRetry = true
            }
            
            if needsRetry && !Task.isCancelled {
                if let authVM = authViewModel {
                    let refreshed = await authVM.refreshTokenIfNeeded()
                    if refreshed && !Task.isCancelled {
                        workingToken = authVM.accessToken ?? workingToken
                        retryCount += 1
                        continue
                    }
                }
                if !Task.isCancelled {
                    self.error = "Session expired. Please sign in again."
                }
                self.isLoading = false
                return
            }
            
            // 3. Format and assign
            func formatCurrency(_ value: Double) -> String {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.locale = Locale.current
                formatter.minimumFractionDigits = 2
                formatter.maximumFractionDigits = 2
                return formatter.string(from: NSNumber(value: value)) ?? "0.00"
            }
            func formatDate(_ date: Date) -> String {
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMM yyyy"
                return formatter.string(from: date)
            }
            
            if case .success(let unpaidEarnings) = unpaid, !Task.isCancelled {
                let currentMonthEarnings = (try? currentMonth.get()) ?? 0.0
                
                switch prev {
                case .success(let prevPayment?):
                    // Normal case: payment exists
                    let data = PaymentsData(
                        unpaidEarnings: formatCurrency(unpaidEarnings),
                        unpaidEarningsValue: unpaidEarnings,
                        previousPaymentDate: formatDate(prevPayment.date),
                        previousPaymentAmount: formatCurrency(prevPayment.amount),
                        currentMonthEarnings: formatCurrency(currentMonthEarnings),
                        currentMonthEarningsValue: currentMonthEarnings
                    )
                    if !Task.isCancelled {
                        self.paymentsData = data
                        self.lastUpdateTime = Date()
                        self.error = nil
                        self.hasLoaded = true
                    }
                case .success(nil):
                    // No previous payment exists
                    let data = PaymentsData(
                        unpaidEarnings: formatCurrency(unpaidEarnings),
                        unpaidEarningsValue: unpaidEarnings,
                        previousPaymentDate: "No payments yet",
                        previousPaymentAmount: "-",
                        currentMonthEarnings: formatCurrency(currentMonthEarnings),
                        currentMonthEarningsValue: currentMonthEarnings
                    )
                    if !Task.isCancelled {
                        self.paymentsData = data
                        self.lastUpdateTime = Date()
                        self.error = nil
                        self.hasLoaded = true
                    }
                case .failure(let err):
                    switch err {
                    case .unauthorized:
                        // This case is already handled above
                        break
                    case .requestFailed(let message):
                        // Handle cancellation more gracefully
                        if message.contains("Request was cancelled") || Task.isCancelled {
                            // Silently ignore cancellation errors during refresh
                            break
                        }
                        // Check for specific empty state conditions
                        if message.contains("FAILED_PRECONDITION|") {
                            let actualMessage = String(message.dropFirst("FAILED_PRECONDITION|".count))
                            if !Task.isCancelled {
                                self.showEmptyState = true
                                self.emptyStateMessage = actualMessage
                                self.error = nil
                            }
                            self.isLoading = false
                            return
                        }
                        if !Task.isCancelled {
                            self.error = "Failed to load previous payment: \(message)"
                        }
                    default:
                        if !Task.isCancelled {
                            self.error = "Failed to load previous payment: \(err)"
                        }
                    }
                }
            } else if case .failure(let err) = unpaid, !Task.isCancelled {
                switch err {
                case .unauthorized:
                    // This case is already handled above
                    break
                case .requestFailed(let message):
                    // Handle cancellation more gracefully
                    if message.contains("Request was cancelled") || Task.isCancelled {
                        // Silently ignore cancellation errors during refresh
                        break
                    }
                    // Check for specific empty state conditions
                    if message.contains("FAILED_PRECONDITION|") {
                        let actualMessage = String(message.dropFirst("FAILED_PRECONDITION|".count))
                        if !Task.isCancelled {
                            self.showEmptyState = true
                            self.emptyStateMessage = actualMessage
                            self.error = nil
                        }
                        self.isLoading = false
                        return
                    }
                    if !Task.isCancelled {
                        self.error = "Failed to load unpaid earnings: \(message)"
                    }
                default:
                    if !Task.isCancelled {
                        self.error = "Failed to load unpaid earnings: \(err)"
                    }
                }
            }
            
            if !Task.isCancelled {
                self.isLoading = false
            }
            break // Exit the retry loop
        }
        
        if retryCount >= maxRetries && !Task.isCancelled {
            self.error = "Failed to refresh authentication. Please sign in again."
            self.isLoading = false
        } else if !Task.isCancelled {
            self.isLoading = false
        }
    }
} 
