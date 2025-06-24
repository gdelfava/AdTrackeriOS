import Foundation
import WatchConnectivity

@MainActor
class WatchDataSyncService: NSObject, ObservableObject {
    static let shared = WatchDataSyncService()
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // Send summary data to watch
    func sendSummaryData(_ summaryData: AdSenseSummaryData, todayMetrics: AdSenseDayMetrics? = nil) {
        print("📱 [iOS] Attempting to send data to watch...")
        print("📱 [iOS] Session state: \(WCSession.default.activationState.rawValue)")
        print("📱 [iOS] Session reachable: \(WCSession.default.isReachable)")
        print("📱 [iOS] Watch app installed: \(WCSession.default.isWatchAppInstalled)")
        
        // For simulator testing, be less strict about reachability
        guard WCSession.default.activationState == .activated else {
            print("📱 [iOS] Watch session not activated - state: \(WCSession.default.activationState.rawValue)")
            return
        }
        
        // In simulators, even if not reachable, try to send via updateApplicationContext
        if !WCSession.default.isReachable {
            print("📱 [iOS] Watch not reachable but trying updateApplicationContext anyway (simulator workaround)")
        }
        
        // Create dictionary with summary and metrics data
        var watchContext: [String: Any] = [
            "todayEarnings": summaryData.today,
            "yesterdayEarnings": summaryData.yesterday,
            "last7DaysEarnings": summaryData.last7Days,
            "thisMonthEarnings": summaryData.thisMonth,
            "lastMonthEarnings": summaryData.lastMonth,
            "lastUpdated": Date().timeIntervalSince1970
        ]
        
        // Add delta information
        if let todayDelta = summaryData.todayDelta {
            watchContext["todayDelta"] = todayDelta
            watchContext["todayDeltaPositive"] = summaryData.todayDeltaPositive ?? false
        }
        if let yesterdayDelta = summaryData.yesterdayDelta {
            watchContext["yesterdayDelta"] = yesterdayDelta
            watchContext["yesterdayDeltaPositive"] = summaryData.yesterdayDeltaPositive ?? false
        }
        if let last7DaysDelta = summaryData.last7DaysDelta {
            watchContext["last7DaysDelta"] = last7DaysDelta
            watchContext["last7DaysDeltaPositive"] = summaryData.last7DaysDeltaPositive ?? false
        }
        if let thisMonthDelta = summaryData.thisMonthDelta {
            watchContext["thisMonthDelta"] = thisMonthDelta
            watchContext["thisMonthDeltaPositive"] = summaryData.thisMonthDeltaPositive ?? false
        }
        
        // Add today's metrics if available
        if let metrics = todayMetrics {
            watchContext["todayClicks"] = metrics.clicks
            watchContext["todayPageViews"] = metrics.pageViews
            watchContext["todayImpressions"] = metrics.impressions
        }
        
        do {
            try WCSession.default.updateApplicationContext(watchContext)
            print("📱 [iOS] Successfully sent data to watch via updateApplicationContext")
        } catch {
            print("📱 [iOS] Failed to send data to watch: \(error)")
        }
    }
    
    // Send a simple status update
    func sendQuickUpdate(earnings: String, lastUpdated: Date) {
        guard WCSession.default.isReachable || WCSession.default.activationState == .activated else {
            print("Watch session not available")
            return
        }
        
        let quickData: [String: Any] = [
            "quickUpdate": true,
            "earnings": earnings,
            "lastUpdated": lastUpdated.timeIntervalSince1970
        ]
        
        do {
            try WCSession.default.updateApplicationContext(quickData)
            print("Successfully sent quick update to watch")
        } catch {
            print("Failed to send quick update to watch: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchDataSyncService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("📱 [iOS] WC Session activation failed with error: \(error.localizedDescription)")
            return
        }
        print("📱 [iOS] WC Session activated with state: \(activationState.rawValue)")
        print("📱 [iOS] Watch app installed: \(session.isWatchAppInstalled)")
        print("📱 [iOS] Session reachable: \(session.isReachable)")
    }
    
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("WC Session did become inactive")
    }
    
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("📱 [iOS] WC Session did deactivate")
        // Reactivate the session
        session.activate()
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📱 [iOS] Received message from watch with reply handler: \(message)")
        
        if let action = message["action"] as? String, action == "requestUpdate" {
            print("📱 [iOS] Watch requested data update - responding via reply handler")
            
            // For testing, send sample data immediately via reply handler
            let testContext: [String: Any] = [
                "todayEarnings": "R 15,75",
                "yesterdayEarnings": "R 12,30",
                "last7DaysEarnings": "R 95,40",
                "thisMonthEarnings": "R 380,25",
                "lastMonthEarnings": "R 325,90",
                "todayDelta": "+R 3,45 (+28.0%)",
                "todayDeltaPositive": true,
                "yesterdayDelta": "-R 0,50 (-3.9%)",
                "yesterdayDeltaPositive": false,
                "last7DaysDelta": "+R 20,15 (+26.8%)",
                "last7DaysDeltaPositive": true,
                "thisMonthDelta": "+R 54,35 (+16.7%)",
                "thisMonthDeltaPositive": true,
                "todayClicks": "189",
                "todayPageViews": "2,845",
                "todayImpressions": "9,320",
                "lastUpdated": Date().timeIntervalSince1970,
                "status": "success"
            ]
            
            // Send response via reply handler
            replyHandler(testContext)
            print("📱 [iOS] Sent test data to watch via reply handler")
        } else {
            // Send a basic acknowledgment if no specific action
            replyHandler(["status": "received", "timestamp": Date().timeIntervalSince1970])
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📱 [iOS] Received message from watch (no reply handler): \(message)")
        // Handle messages that don't expect a reply
    }
} 
