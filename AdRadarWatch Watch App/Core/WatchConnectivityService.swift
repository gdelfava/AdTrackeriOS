import Foundation
import WatchConnectivity
import SwiftUI

@MainActor
class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()
    
    @Published var summaryData: WatchSummaryData?
    @Published var isConnected: Bool = false
    @Published var lastUpdateTime: Date?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("⌚ [Watch] WC Session activation initiated")
        } else {
            print("⌚ [Watch] WC Session not supported")
        }
    }
    
    func requestDataFromPhone() {
        print("⌚ [Watch] Requesting data from iPhone...")
        
        guard WCSession.default.activationState == .activated else {
            print("⌚ [Watch] Session not activated")
            errorMessage = "Connection not available"
            return
        }
        
        // Check if iPhone is reachable before attempting to send message
        guard WCSession.default.isReachable else {
            print("⌚ [Watch] iPhone not reachable, will wait for application context updates")
            errorMessage = "iPhone not reachable"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let message: [String: Any] = [
            "action": "requestUpdate",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        WCSession.default.sendMessage(message, replyHandler: { [weak self] reply in
            DispatchQueue.main.async {
                print("⌚ [Watch] Received reply from iPhone")
                self?.handleDataUpdate(reply)
                self?.isLoading = false
            }
        }) { [weak self] error in
            DispatchQueue.main.async {
                print("⌚ [Watch] Failed to send message: \(error.localizedDescription)")
                // Don't show error immediately, data might come via application context
                self?.isLoading = false
                
                // Only show error if we don't have any existing data
                if self?.summaryData == nil {
                    self?.errorMessage = "Waiting for iPhone..."
                }
            }
        }
    }
    
    private func handleDataUpdate(_ context: [String: Any]) {
        let data = WatchSummaryData(from: context)
        self.summaryData = data
        self.lastUpdateTime = data.lastUpdated
        print("⌚ [Watch] Received data update: \(data.todayEarnings)")
    }
    
    func refreshData() {
        requestDataFromPhone()
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            if let error = error {
                print("⌚ [Watch] WC Session activation failed: \(error.localizedDescription)")
                self.errorMessage = "Connection failed"
                return
            }
            
            print("⌚ [Watch] WC Session activated with state: \(activationState.rawValue)")
            print("⌚ [Watch] iPhone reachable: \(session.isReachable)")
            self.isConnected = activationState == .activated
            
            if activationState == .activated {
                // Only request data if iPhone is reachable, otherwise wait for application context
                if session.isReachable {
                    self.requestDataFromPhone()
                } else {
                    print("⌚ [Watch] iPhone not reachable on activation, waiting for application context updates")
                }
            }
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            print("⌚ [Watch] Received application context: \(applicationContext)")
            self.handleDataUpdate(applicationContext)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            print("⌚ [Watch] Received message: \(message)")
            self.handleDataUpdate(message)
        }
    }
    
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        Task { @MainActor in
            print("⌚ [Watch] Received message with reply handler: \(message)")
            self.handleDataUpdate(message)
            replyHandler(["status": "received"])
        }
    }
} 