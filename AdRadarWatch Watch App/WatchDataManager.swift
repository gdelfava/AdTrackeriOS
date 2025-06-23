import Foundation
import WatchConnectivity

@MainActor
class WatchDataManager: NSObject, ObservableObject {
    static let shared = WatchDataManager()
    
    @Published var summaryData: WatchSummaryData?
    @Published var isConnected: Bool = false
    @Published var lastUpdated: Date?
    @Published var connectionStatus: String = "Connecting..."
    
    private let userDefaults = UserDefaults.standard
    private let summaryDataKey = "WatchSummaryData"
    private let lastUpdatedKey = "WatchLastUpdated"
    
    private override init() {
        super.init()
        loadCachedData()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    private func loadCachedData() {
        // Load cached summary data
        if let data = userDefaults.data(forKey: summaryDataKey) {
            do {
                let decoder = JSONDecoder()
                summaryData = try decoder.decode(WatchSummaryData.self, from: data)
            } catch {
                print("Failed to decode cached summary data: \(error)")
            }
        }
        
        // Load last updated timestamp
        if let timestamp = userDefaults.object(forKey: lastUpdatedKey) as? Date {
            lastUpdated = timestamp
        }
    }
    
    private func saveSummaryData(_ data: WatchSummaryData) {
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(data)
            userDefaults.set(encoded, forKey: summaryDataKey)
            userDefaults.set(data.lastUpdated, forKey: lastUpdatedKey)
        } catch {
            print("Failed to save summary data: \(error)")
        }
    }
    
    // Public method to refresh data if available
    func refreshData() {
        print("⌚ [Watch] Refresh button pressed")
        print("⌚ [Watch] Session supported: \(WCSession.isSupported())")
        print("⌚ [Watch] Session reachable: \(WCSession.default.isReachable)")
        print("⌚ [Watch] Session state: \(WCSession.default.activationState.rawValue)")
        
        connectionStatus = "Requesting update..."
        print("⌚ [Watch] Sending refresh request to iPhone")
        
        // Send a request to the iPhone for fresh data
        let message = ["action": "requestUpdate"]
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            DispatchQueue.main.async {
                print("⌚ [Watch] Failed to send message: \(error.localizedDescription)")
                self.connectionStatus = "Failed to request update - Loading test data"
                // Fallback to test data if message fails
                self.loadTestData()
            }
        }
    }
    
    // Public method to manually load test data
    func loadTestDataManually() {
        loadTestData()
    }
    
    // Load test data for development/testing when iPhone isn't reachable
    private func loadTestData() {
        let testData = WatchSummaryData(
            todayEarnings: "R 12,50",
            yesterdayEarnings: "R 8,75",
            last7DaysEarnings: "R 85,20",
            thisMonthEarnings: "R 320,45",
            lastMonthEarnings: "R 275,80",
            todayDelta: "+R 3,75 (+43.2%)",
            todayDeltaPositive: true,
            yesterdayDelta: "-R 1,25 (-12.5%)",
            yesterdayDeltaPositive: false,
            last7DaysDelta: "+R 15,30 (+21.9%)",
            last7DaysDeltaPositive: true,
            thisMonthDelta: "+R 44,65 (+16.2%)",
            thisMonthDeltaPositive: true,
            todayClicks: "145",
            todayPageViews: "2,350",
            todayImpressions: "8,750",
            lastUpdated: Date()
        )
        
        self.summaryData = testData
        self.lastUpdated = testData.lastUpdated
        self.saveSummaryData(testData)
        self.connectionStatus = "Test data loaded"
        print("⌚ [Watch] Test data loaded successfully")
    }
}

// MARK: - WCSessionDelegate
extension WatchDataManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("⌚ [Watch] WC Session activation failed: \(error.localizedDescription)")
                self.connectionStatus = "Connection failed: \(error.localizedDescription)"
                self.isConnected = false
                return
            }
            
            print("⌚ [Watch] WC Session activated with state: \(activationState.rawValue)")
            print("⌚ [Watch] Session reachable: \(session.isReachable)")
            print("⌚ [Watch] iPhone app installed: \(session.isCompanionAppInstalled)")
            
            switch activationState {
            case .activated:
                self.isConnected = true
                self.connectionStatus = session.isReachable ? "Connected" : "iPhone not reachable"
            case .inactive:
                self.isConnected = false
                self.connectionStatus = "Inactive"
            case .notActivated:
                self.isConnected = false
                self.connectionStatus = "Not activated"
            @unknown default:
                self.isConnected = false
                self.connectionStatus = "Unknown state"
            }
            print("⌚ [Watch] Final connection status: \(self.connectionStatus)")
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            // Handle full summary data from context dictionary
            if let todayEarnings = applicationContext["todayEarnings"] as? String {
                let watchData = WatchSummaryData(
                    todayEarnings: todayEarnings,
                    yesterdayEarnings: applicationContext["yesterdayEarnings"] as? String ?? "0.00",
                    last7DaysEarnings: applicationContext["last7DaysEarnings"] as? String ?? "0.00",
                    thisMonthEarnings: applicationContext["thisMonthEarnings"] as? String ?? "0.00",
                    lastMonthEarnings: applicationContext["lastMonthEarnings"] as? String ?? "0.00",
                    todayDelta: applicationContext["todayDelta"] as? String,
                    todayDeltaPositive: applicationContext["todayDeltaPositive"] as? Bool,
                    yesterdayDelta: applicationContext["yesterdayDelta"] as? String,
                    yesterdayDeltaPositive: applicationContext["yesterdayDeltaPositive"] as? Bool,
                    last7DaysDelta: applicationContext["last7DaysDelta"] as? String,
                    last7DaysDeltaPositive: applicationContext["last7DaysDeltaPositive"] as? Bool,
                    thisMonthDelta: applicationContext["thisMonthDelta"] as? String,
                    thisMonthDeltaPositive: applicationContext["thisMonthDeltaPositive"] as? Bool,
                    todayClicks: applicationContext["todayClicks"] as? String,
                    todayPageViews: applicationContext["todayPageViews"] as? String,
                    todayImpressions: applicationContext["todayImpressions"] as? String,
                    lastUpdated: {
                        if let timestamp = applicationContext["lastUpdated"] as? TimeInterval {
                            return Date(timeIntervalSince1970: timestamp)
                        }
                        return Date()
                    }()
                )
                
                self.summaryData = watchData
                self.lastUpdated = watchData.lastUpdated
                self.saveSummaryData(watchData)
                self.connectionStatus = "Data updated"
                print("⌚ [Watch] Received full summary data from iPhone - Today: \(todayEarnings)")
            }
            
            // Handle quick updates
            else if let isQuickUpdate = applicationContext["quickUpdate"] as? Bool, isQuickUpdate {
                if let earnings = applicationContext["earnings"] as? String,
                   let timestamp = applicationContext["lastUpdated"] as? TimeInterval {
                    
                    // Update existing data with new earnings if we have cached data
                    if var currentData = self.summaryData {
                        // Create updated data with new today earnings
                        let updatedData = WatchSummaryData(
                            todayEarnings: earnings,
                            yesterdayEarnings: currentData.yesterdayEarnings,
                            last7DaysEarnings: currentData.last7DaysEarnings,
                            thisMonthEarnings: currentData.thisMonthEarnings,
                            lastMonthEarnings: currentData.lastMonthEarnings,
                            todayDelta: currentData.todayDelta,
                            todayDeltaPositive: currentData.todayDeltaPositive,
                            yesterdayDelta: currentData.yesterdayDelta,
                            yesterdayDeltaPositive: currentData.yesterdayDeltaPositive,
                            last7DaysDelta: currentData.last7DaysDelta,
                            last7DaysDeltaPositive: currentData.last7DaysDeltaPositive,
                            thisMonthDelta: currentData.thisMonthDelta,
                            thisMonthDeltaPositive: currentData.thisMonthDeltaPositive,
                            todayClicks: currentData.todayClicks,
                            todayPageViews: currentData.todayPageViews,
                            todayImpressions: currentData.todayImpressions,
                            lastUpdated: Date(timeIntervalSince1970: timestamp)
                        )
                        
                        self.summaryData = updatedData
                        self.lastUpdated = Date(timeIntervalSince1970: timestamp)
                        self.saveSummaryData(updatedData)
                        self.connectionStatus = "Quick update received"
                        print("Received quick update on watch")
                    }
                }
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            print("⌚ [Watch] Session reachability changed to: \(session.isReachable)")
            self.isConnected = session.isReachable
            self.connectionStatus = session.isReachable ? "Connected" : "iPhone not reachable"
        }
    }
}

 