import Foundation

// MARK: - Response Models

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

struct AccountsResponse: Codable {
    let accounts: [Account]
}

struct Account: Codable {
    let name: String
    let displayName: String
    let pendingTasks: [String]?
    let timeZone: TimeZone?
    let createTime: String?
    let premium: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case displayName
        case pendingTasks
        case timeZone
        case createTime
        case premium
    }
}

struct TimeZone: Codable {
    let id: String
}

// MARK: - Error Types

enum AdSenseError: Error {
    case invalidURL
    case requestFailed(String)
    case noAccountID
    case unauthorized
    case invalidResponse
    case decodingError(String)
}

class AdSenseAPI {
    static let shared = AdSenseAPI()
    private init() {}
    
    func fetchSummaryData(accessToken: String) async -> Result<AdSenseSummaryData, AdSenseError> {
        // TODO: Implement real API call
        // Placeholder: Simulate network delay and return dummy data
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Log the response data for debugging
            print("Generating dummy summary data")
            
            let dummy = AdSenseSummaryData(
                today: "R 17,92",
                yesterday: "R 76,55",
                last7Days: "R 604,84",
                thisMonth: "R 849,32",
                lastMonth: "R 2 403,58",
                lifetime: "R 261 856,93",
                todayDelta: "+12.5%",
                todayDeltaPositive: true,
                yesterdayDelta: "-5.2%",
                yesterdayDeltaPositive: false,
                last7DaysDelta: "+8.3%",
                last7DaysDeltaPositive: true,
                thisMonthDelta: "+15.7%",
                thisMonthDeltaPositive: true,
                lastMonthDelta: "-2.1%",
                lastMonthDeltaPositive: false
            )
            
            // Log the encoded data for debugging
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let jsonData = try? encoder.encode(dummy),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Encoded summary data: \(jsonString)")
            }
            
            return .success(dummy)
        } catch {
            print("Error generating summary data: \(error)")
            return .failure(.decodingError("Failed to generate summary data: \(error.localizedDescription)"))
        }
    }
    
    // Fetch the user's AdSense account ID
    static func fetchAccountID(accessToken: String) async -> Result<String, AdSenseError> {
        guard let url = URL(string: "https://adsense.googleapis.com/v2/accounts") else {
            return .failure(.invalidURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            // Check for cancellation before making the request
            try Task.checkCancellation()
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check for cancellation after receiving the response
            try Task.checkCancellation()
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Error: Invalid response type")
                return .failure(.requestFailed("Invalid response type"))
            }
            
            print("HTTP Status Code: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Data: \(responseString)")
            }
            
            switch httpResponse.statusCode {
            case 200:
                do {
                    let decoder = JSONDecoder()
                    let accounts = try decoder.decode(AccountsResponse.self, from: data)
                    if let firstAccount = accounts.accounts.first {
                        return .success(firstAccount.name)
                    } else {
                        return .failure(.noAccountID)
                    }
                } catch {
                    print("Decoding error: \(error)")
                    return .failure(.decodingError(error.localizedDescription))
                }
            case 401:
                return .failure(.unauthorized)
            case 403:
                return .failure(.requestFailed("Access forbidden. Please check your AdSense permissions."))
            case 429:
                return .failure(.requestFailed("Rate limit exceeded. Please try again later."))
            case 500...599:
                return .failure(.requestFailed("AdSense API server error. Please try again later."))
            default:
                return .failure(.requestFailed("Unexpected error: HTTP \(httpResponse.statusCode)"))
            }
        } catch let error as URLError where error.code == .cancelled {
            print("Request was cancelled")
            return .failure(.requestFailed("Request was cancelled"))
        } catch {
            print("Network error: \(error)")
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }
    
    // Fetch earnings for a given date range
    func fetchReport(accessToken: String, accountID: String, startDate: String, endDate: String) async -> Result<Double, AdSenseError> {
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/reports:generate?metrics=ESTIMATED_EARNINGS&dateRange=REPORTING_DATE_RANGE_UNSPECIFIED&startDate.year=\(startDate.prefix(4))&startDate.month=\(startDate.dropFirst(5).prefix(2))&startDate.day=\(startDate.suffix(2))&endDate.year=\(endDate.prefix(4))&endDate.month=\(endDate.dropFirst(5).prefix(2))&endDate.day=\(endDate.suffix(2))"
        guard let url = URL(string: urlString) else {
            return .failure(.invalidURL)
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        print("Requesting: \(url)")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Response: \(String(data: data, encoding: .utf8) ?? "<no data>")")
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return .failure(.requestFailed("Request failed"))
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let rows = json?["rows"] as? [[String: Any]],
               let firstRow = rows.first,
               let cells = firstRow["cells"] as? [[String: Any]],
               let valueString = cells.first?["value"] as? String,
               let value = Double(valueString) {
                return .success(value)
            } else {
                return .success(0.0) // No data, treat as zero
            }
        } catch {
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }
    
    /// Fetches the user's unpaid earnings from AdSense using the payments endpoint (entry with 'unpaid' in the name).
    func fetchUnpaidEarnings(accessToken: String, accountID: String) async -> Result<Double, AdSenseError> {
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/payments"
        guard let url = URL(string: urlString) else { return .failure(.invalidURL) }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Payments JSON: \(String(data: data, encoding: .utf8) ?? "<no data>")")
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return .failure(.requestFailed("Request failed"))
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let payments = json?["payments"] as? [[String: Any]] {
                // Find the unpaid entry
                if let unpaid = payments.first(where: { ($0["name"] as? String)?.contains("unpaid") == true }),
                   let amountString = unpaid["amount"] as? String {
                    let cleaned = amountString.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)
                    if let value = Double(cleaned) {
                        return .success(value)
                    }
                }
                // If not found, treat as zero
                return .success(0.0)
            } else {
                return .success(0.0)
            }
        } catch {
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }
    
    /// Fetches the user's previous payment date and amount from AdSense using the payments endpoint.
    func fetchPreviousPayment(accessToken: String, accountID: String) async -> Result<(date: Date, amount: Double)?, AdSenseError> {
        let urlString = "https://adsense.googleapis.com/v2/\(accountID)/payments"
        guard let url = URL(string: urlString) else { return .failure(.invalidURL) }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print("Payments JSON: \(String(data: data, encoding: .utf8) ?? "<no data>")")
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return .failure(.requestFailed("Request failed"))
            }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let payments = json?["payments"] as? [[String: Any]] {
                // Find the most recent payment with a date (not the unpaid one)
                if let paid = payments.first(where: { $0["date"] != nil }),
                   let amountString = paid["amount"] as? String,
                   let dateDict = paid["date"] as? [String: Any],
                   let year = dateDict["year"] as? Int,
                   let month = dateDict["month"] as? Int,
                   let day = dateDict["day"] as? Int {
                    let cleaned = amountString.replacingOccurrences(of: "[^0-9.-]", with: "", options: .regularExpression)
                    if let amount = Double(cleaned) {
                        var dateComponents = DateComponents()
                        dateComponents.year = year
                        dateComponents.month = month
                        dateComponents.day = day
                        let calendar = Calendar.current
                        if let date = calendar.date(from: dateComponents) {
                            return .success((date: date, amount: amount))
                        }
                    }
                }
                // If not found, treat as no previous payment
                return .success(nil)
            } else {
                return .success(nil)
            }
        } catch {
            return .failure(.requestFailed("Network error: \(error.localizedDescription)"))
        }
    }

    static let appGroupID = "group.com.delteqws.AdTracker" // Replace with your real App Group ID
    static let summaryKey = "summaryData"

    func saveSummaryToSharedContainer(_ summary: AdSenseSummaryData) {
        if let data = try? JSONEncoder().encode(summary) {
            let defaults = UserDefaults(suiteName: Self.appGroupID)
            defaults?.set(data, forKey: Self.summaryKey)
        }
    }

    func loadSummaryFromSharedContainer() -> AdSenseSummaryData? {
        let defaults = UserDefaults(suiteName: Self.appGroupID)
        if let data = defaults?.data(forKey: Self.summaryKey),
           let summary = try? JSONDecoder().decode(AdSenseSummaryData.self, from: data) {
            return summary
        }
        return nil
    }
} 