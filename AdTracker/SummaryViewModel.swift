import Foundation
import Combine

@MainActor
class SummaryViewModel: ObservableObject {
    @Published var summaryData: AdSenseSummaryData? = nil
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var last7DaysData: AdSenseSummaryData? = nil
    @Published var last30DaysData: AdSenseSummaryData? = nil
    @Published var thisMonthData: AdSenseSummaryData? = nil
    @Published var lastMonthData: AdSenseSummaryData? = nil
    
    var accessToken: String?
    private var accountID: String?
    var authViewModel: AuthViewModel?
    private var fetchTask: Task<Void, Never>?
    
    init(accessToken: String?, authViewModel: AuthViewModel? = nil) {
        self.accessToken = accessToken
        self.authViewModel = authViewModel
        if accessToken != nil {
            fetchTask = Task { await fetchSummary() }
        }
    }
    
    deinit {
        fetchTask?.cancel()
    }
    
    func fetchSummary() async {
        // Cancel any existing fetch task
        fetchTask?.cancel()
        
        // Create a new fetch task
        fetchTask = Task {
            guard let token = accessToken else {
                error = "No access token available"
                isLoading = false
                return
            }
            
            isLoading = true
            error = nil
            
            // Try to refresh token if we have access to AuthViewModel
            if let authVM = authViewModel {
                let refreshed = await authVM.refreshTokenIfNeeded()
                if refreshed {
                    self.accessToken = authVM.accessToken
                }
            }
            
            // 1. Fetch account ID with retry logic
            var currentToken = token
            var retryCount = 0
            let maxRetries = 2
            
            while retryCount < maxRetries {
                // Check for task cancellation
                if Task.isCancelled {
                    self.error = "Request was cancelled"
                    self.isLoading = false
                    return
                }
                
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
                    case .requestFailed(let message):
                        self.error = "Failed to get AdSense account: \(message)"
                    case .noAccountID:
                        self.error = "No AdSense account found."
                    case .invalidURL:
                        self.error = "Invalid API URL configuration."
                    case .invalidResponse:
                        self.error = "Invalid response from AdSense API."
                    case .decodingError(let message):
                        self.error = "Failed to decode response: \(message)"
                    }
                    self.isLoading = false
                    return
                }
                break
            }
            
            guard self.accountID != nil else {
                self.error = "No AdSense account found."
                self.isLoading = false
                return
            }
            
            do {
                // Create an immutable copy of the token for concurrent use
                let token = currentToken
                
                print("Starting to fetch summary data with token: \(token.prefix(10))...")
                
                // Check for task cancellation before starting requests
                if Task.isCancelled {
                    self.error = "Request was cancelled"
                    self.isLoading = false
                    return
                }
                
                // Fetch data for all date ranges
                async let last7DaysData = AdSenseAPI.shared.fetchSummaryData(accessToken: token)
                async let last30DaysData = AdSenseAPI.shared.fetchSummaryData(accessToken: token)
                async let thisMonthData = AdSenseAPI.shared.fetchSummaryData(accessToken: token)
                async let lastMonthData = AdSenseAPI.shared.fetchSummaryData(accessToken: token)
                
                // Wait for all requests to complete
                let (last7DaysResult, last30DaysResult, thisMonthResult, lastMonthResult) = await (
                    last7DaysData,
                    last30DaysData,
                    thisMonthData,
                    lastMonthData
                )
                
                // Check for task cancellation after receiving responses
                if Task.isCancelled {
                    self.error = "Request was cancelled"
                    self.isLoading = false
                    return
                }
                
                // Process results with detailed error handling
                do {
                    self.last7DaysData = try last7DaysResult.get()
                    print("Successfully fetched last 7 days data")
                } catch {
                    print("Error fetching last 7 days data: \(error)")
                    throw error
                }
                
                do {
                    self.last30DaysData = try last30DaysResult.get()
                    print("Successfully fetched last 30 days data")
                } catch {
                    print("Error fetching last 30 days data: \(error)")
                    throw error
                }
                
                do {
                    self.thisMonthData = try thisMonthResult.get()
                    print("Successfully fetched this month data")
                } catch {
                    print("Error fetching this month data: \(error)")
                    throw error
                }
                
                do {
                    self.lastMonthData = try lastMonthResult.get()
                    print("Successfully fetched last month data")
                } catch {
                    print("Error fetching last month data: \(error)")
                    throw error
                }
                
                // Set the main summary data to the last 7 days data
                self.summaryData = self.last7DaysData
                print("Successfully updated all summary data")
                
            } catch let error as AdSenseError {
                print("AdSense API error: \(error)")
                switch error {
                case .decodingError(let message):
                    self.error = "Failed to decode response: \(message)"
                case .requestFailed(let message):
                    self.error = "Request failed: \(message)"
                case .unauthorized:
                    self.error = "Session expired. Please sign in again."
                case .noAccountID:
                    self.error = "No AdSense account found."
                case .invalidURL:
                    self.error = "Invalid API URL configuration."
                case .invalidResponse:
                    self.error = "Invalid response from AdSense API."
                }
            } catch {
                print("Unexpected error: \(error)")
                self.error = "An unexpected error occurred: \(error.localizedDescription)"
            }
            
            self.isLoading = false
        }
    }
} 
