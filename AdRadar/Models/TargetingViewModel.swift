import Foundation
import SwiftUI

@MainActor
class TargetingViewModel: ObservableObject {
    @Published var targetingData: [TargetingData] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedFilter: DateFilter = .last7Days
    @Published var hasLoaded = false
    
    var accessToken: String?
    var authViewModel: AuthViewModel?
    private var accountID: String?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
    }
    
    func fetchTargetingData() async {
        guard let currentToken = accessToken else {
            self.error = "No access token available"
            self.isLoading = false
            return
        }
        
        // If in demo mode, use demo data
        if let authVM = authViewModel, authVM.isDemoMode {
            let dateRange = selectedFilter.dateRange
            let mockData = DemoDataProvider.shared.generateMockDataForRange(
                startDate: dateRange.start,
                endDate: dateRange.end
            )
            self.targetingData = mockData.targeting
            self.isLoading = false
            self.error = nil
            self.hasLoaded = true
            return
        }
        
        // Get account ID if not already available
        if accountID == nil {
            let accountResult = await AdSenseAPI.fetchAccountID(accessToken: currentToken)
            switch accountResult {
            case .success(let id):
                self.accountID = id
            case .failure(let error):
                self.error = "Failed to get account ID: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
        }
        
        guard let accountID = self.accountID else {
            self.error = "No AdSense account found"
            self.isLoading = false
            return
        }
        
        self.isLoading = true
        self.error = nil
        
        let dateRange = selectedFilter.dateRange
        let result = await fetchTargetingDataFromAPI(
            accountID: accountID,
            accessToken: currentToken,
            startDate: dateRange.start,
            endDate: dateRange.end
        )
        
        switch result {
        case .success(let targeting):
            self.targetingData = targeting
            self.hasLoaded = true
        case .failure(let error):
            self.error = error.localizedDescription
        }
        
        self.isLoading = false
    }
    
    private func fetchTargetingDataFromAPI(accountID: String, accessToken: String, startDate: Date, endDate: Date) async -> Result<[TargetingData], AdSenseError> {
        guard NetworkMonitor.shared.shouldProceedWithRequest() else {
            return .failure(.requestFailed("No internet connection"))
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)
        
        // Define the metrics and dimensions we want - as specified by the user
        let metrics = [
            "ESTIMATED_EARNINGS",
            "IMPRESSIONS",
            "CLICKS",
            "IMPRESSIONS_CTR",
            "IMPRESSIONS_RPM",
            "AD_REQUESTS",
            "PAGE_VIEWS"
        ]
        
        let metricsQuery = metrics.map { "metrics=\($0)" }.joined(separator: "&")
        
        // Parse date components properly
        let startComponents = start.split(separator: "-")
        let endComponents = end.split(separator: "-")
        
        guard startComponents.count == 3, endComponents.count == 3 else {
            return .failure(.invalidURL)
        }
        
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/reports:generate?\(metricsQuery)&dimensions=TARGETING_TYPE_NAME&startDate.year=\(startComponents[0])&startDate.month=\(startComponents[1])&startDate.day=\(startComponents[2])&endDate.year=\(endComponents[0])&endDate.month=\(endComponents[1])&endDate.day=\(endComponents[2])"
        
        // Debug: Print the URL being constructed
        print("Targeting API URL: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("Failed to create URL from string: \(urlString)")
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        do {
            try Task.checkCancellation()
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            try Task.checkCancellation()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.invalidResponse)
            }
            
            // Debug: Print response details
            print("Targeting API HTTP Status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Targeting API Response: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                guard let rows = json?["rows"] as? [[String: Any]] else {
                    print("No rows found in targeting response")
                    return .success([]) // No data available
                }
                
                let targetingItems = rows.compactMap { row -> TargetingData? in
                    guard let cells = row["cells"] as? [[String: Any]] else { return nil }
                    
                    // The first cell contains the targeting type
                    let targetingType = cells.first?["value"] as? String ?? "Unknown"
                    
                    // Initialize default values
                    var earnings = "0"
                    var impressions = "0"
                    var clicks = "0"
                    var ctr = "0"
                    var rpm = "0"
                    var requests = "0"
                    var pageViews = "0"
                    
                    // Map the remaining cells to metrics
                    // The order should be: targeting_type, earnings, impressions, clicks, ctr, rpm, requests, pageViews
                    if cells.count >= 2 {
                        earnings = cells[1]["value"] as? String ?? "0"
                    }
                    if cells.count >= 3 {
                        impressions = cells[2]["value"] as? String ?? "0"
                    }
                    if cells.count >= 4 {
                        clicks = cells[3]["value"] as? String ?? "0"
                    }
                    if cells.count >= 5 {
                        ctr = cells[4]["value"] as? String ?? "0"
                    }
                    if cells.count >= 6 {
                        rpm = cells[5]["value"] as? String ?? "0"
                    }
                    if cells.count >= 7 {
                        requests = cells[6]["value"] as? String ?? "0"
                    }
                    if cells.count >= 8 {
                        pageViews = cells[7]["value"] as? String ?? "0"
                    }
                    
                    return TargetingData(
                        targetingType: targetingType,
                        earnings: earnings,
                        impressions: impressions,
                        clicks: clicks,
                        ctr: ctr,
                        rpm: rpm,
                        requests: requests,
                        pageViews: pageViews
                    )
                }
                
                // Sort by earnings (highest first)
                let sortedTargeting = targetingItems.sorted { 
                    (Double($0.earnings) ?? 0) > (Double($1.earnings) ?? 0)
                }
                
                return .success(sortedTargeting)
                
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden"))
            default:
                return .failure(.requestFailed("Server returned status code \(httpResponse.statusCode)"))
            }
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet:
                return .failure(.requestFailed("No internet connection"))
            case .timedOut:
                return .failure(.requestFailed("Request timed out"))
            case .cannotConnectToHost:
                return .failure(.requestFailed("Cannot connect to server"))
            case .cancelled:
                return .failure(.requestFailed("Request was cancelled"))
            default:
                return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
            }
        } catch {
            return .failure(.requestFailed("Unexpected error: \(error.localizedDescription)"))
        }
    }
} 