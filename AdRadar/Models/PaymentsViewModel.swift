import Foundation
import Combine

struct PaymentsData {
    let unpaidEarnings: String
    let unpaidEarningsValue: Double // Raw value for calculations
    let previousPaymentDate: String
    let previousPaymentAmount: String
}

class PaymentsViewModel: ObservableObject {
    @Published var paymentsData: PaymentsData? = nil
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var hasLoaded: Bool = false
    
    var accessToken: String?
    var authViewModel: AuthViewModel?
    private var accountID: String?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
        if accessToken != nil {
            Task { await fetchPayments() }
        }
    }
    
    @MainActor
    func fetchPayments() async {
        if hasLoaded { return }
        guard let currentToken = accessToken else { 
            self.error = "No access token available. Please sign in again."
            return 
        }
        
        let maxRetries = 2
        var retryCount = 0
        var workingToken = currentToken
        
        while retryCount < maxRetries {
            self.isLoading = true
            self.error = nil
            
            // 1. Fetch account ID
            let accountResult = await AdSenseAPI.fetchAccountID(accessToken: workingToken)
            switch accountResult {
            case .success(let accountID):
                self.accountID = accountID
            case .failure(let err):
                switch err {
                case .unauthorized:
                    if let authVM = authViewModel {
                        let refreshed = await authVM.refreshTokenIfNeeded()
                        if refreshed {
                            workingToken = authVM.accessToken ?? workingToken
                            retryCount += 1
                            continue
                        }
                    }
                    self.error = "Session expired. Please sign in again."
                    self.isLoading = false
                    return
                case .noAccountID:
                    self.error = "No AdSense account found."
                    self.isLoading = false
                    return
                case .requestFailed(let message):
                    self.error = "Failed to get AdSense account: \(message)"
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
                    self.error = "Data parsing error: \(message)"
                    self.isLoading = false
                    return
                }
            }
            
            guard let accountID = self.accountID else {
                self.error = "No AdSense account found."
                self.isLoading = false
                return
            }
            
            // 2. Fetch unpaid earnings and previous payment in parallel
            // Capture the token value to avoid concurrency warnings
            let currentWorkingToken = workingToken
            async let unpaidResult = AdSenseAPI.shared.fetchUnpaidEarnings(accessToken: currentWorkingToken, accountID: accountID)
            async let prevPaymentResult = AdSenseAPI.shared.fetchPreviousPayment(accessToken: currentWorkingToken, accountID: accountID)
            let unpaid = await unpaidResult
            let prev = await prevPaymentResult
            
            // Check for 401 errors in either request
            var needsRetry = false
            if case .failure(let error) = unpaid, case .unauthorized = error {
                needsRetry = true
            }
            if case .failure(let error) = prev, case .unauthorized = error {
                needsRetry = true
            }
            
            if needsRetry {
                if let authVM = authViewModel {
                    let refreshed = await authVM.refreshTokenIfNeeded()
                    if refreshed {
                        workingToken = authVM.accessToken ?? workingToken
                        retryCount += 1
                        continue
                    }
                }
                self.error = "Session expired. Please sign in again."
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
            
            if case .success(let unpaidEarnings) = unpaid {
                switch prev {
                case .success(let prevPayment?):
                    // Normal case: payment exists
                    let data = PaymentsData(
                        unpaidEarnings: formatCurrency(unpaidEarnings),
                        unpaidEarningsValue: unpaidEarnings,
                        previousPaymentDate: formatDate(prevPayment.date),
                        previousPaymentAmount: formatCurrency(prevPayment.amount)
                    )
                    self.paymentsData = data
                    self.error = nil
                    self.hasLoaded = true
                case .success(nil):
                    // No payments yet
                    let data = PaymentsData(
                        unpaidEarnings: formatCurrency(unpaidEarnings),
                        unpaidEarningsValue: unpaidEarnings,
                        previousPaymentDate: "No payments yet",
                        previousPaymentAmount: "-"
                    )
                    self.paymentsData = data
                    self.error = nil
                    self.hasLoaded = true
                case .failure(let err):
                    switch err {
                    case .unauthorized:
                        // This case is already handled above
                        break
                    default:
                        self.error = "Failed to load previous payment: \(err)"
                    }
                }
            } else if case .failure(let err) = unpaid {
                switch err {
                case .unauthorized:
                    // This case is already handled above
                    break
                default:
                    self.error = "Failed to load unpaid earnings: \(err)"
                }
            }
            
            self.isLoading = false
            break // Exit the retry loop
        }
        
        if retryCount >= maxRetries {
            self.error = "Failed to refresh authentication. Please sign in again."
            self.isLoading = false
        }
    }
} 
