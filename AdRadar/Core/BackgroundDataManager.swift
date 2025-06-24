import Foundation
import BackgroundTasks
import UIKit
import WidgetKit

/// Manages background data fetching and synchronization across iOS app, widget, and watch app
@MainActor
class BackgroundDataManager: ObservableObject {
    static let shared = BackgroundDataManager()
    
    // Background task identifiers - must match Info.plist
    private let refreshTaskIdentifier = "com.delteqws.AdRadar.refresh"
    private let processingTaskIdentifier = "com.delteqws.AdRadar.processing"
    
    // Refresh intervals
    private let backgroundRefreshInterval: TimeInterval = 15 * 60 // 15 minutes
    private let appActiveRefreshInterval: TimeInterval = 5 * 60   // 5 minutes
    
    @Published var isBackgroundRefreshEnabled = false
    @Published var lastBackgroundUpdate: Date?
    @Published var backgroundTasksScheduled = 0
    
    private var backgroundTaskCompletionHandler: (() -> Void)?
    
    private init() {
        setupBackgroundTasks()
        checkBackgroundRefreshStatus()
    }
    
    // MARK: - Public Interface
    
    /// Initialize background data manager - call from App.swift
    func initialize() {
        scheduleBackgroundTasks()
        print("[BackgroundDataManager] Initialized with background refresh: \(isBackgroundRefreshEnabled)")
    }
    
    /// Perform immediate data refresh and update all targets
    func performDataRefresh() async -> Bool {
        print("[BackgroundDataManager] Starting immediate data refresh...")
        
        // Check network connectivity
        let isConnected = await withCheckedContinuation { continuation in
            Task.detached {
                continuation.resume(returning: NetworkMonitor.shared.isConnected)
            }
        }
        
        guard isConnected else {
            print("[BackgroundDataManager] No network connection available")
            return false
        }
        
        // Get auth credentials
        guard let accessToken = UserDefaultsManager.shared.getString(forKey: "accessToken"),
              let accountID = UserDefaultsManager.shared.getString(forKey: "adSenseAccountID") else {
            print("[BackgroundDataManager] Missing auth credentials")
            return false
        }
        
        // Fetch fresh data from both APIs
        let success = await fetchAndUpdateData(accessToken: accessToken, accountID: accountID)
        
        if success {
            lastBackgroundUpdate = Date()
            UserDefaultsManager.shared.setDate(Date(), forKey: "lastBackgroundUpdate")
            
            // Update all targets
            await updateAllTargets()
        }
        
        return success
    }
    
    /// Handle app becoming active - perform refresh if needed
    func handleAppBecomeActive() {
        Task {
            let shouldRefresh = await shouldPerformActiveRefresh()
            if shouldRefresh {
                print("[BackgroundDataManager] App became active - performing refresh")
                let _ = await performDataRefresh()
            }
        }
    }
    
    /// Handle app entering background - schedule background tasks
    func handleAppEnterBackground() {
        scheduleBackgroundTasks()
        print("[BackgroundDataManager] App entered background - tasks scheduled")
    }
    
    // MARK: - Background Task Setup
    
    private func setupBackgroundTasks() {
        // Register background app refresh task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshTaskIdentifier, using: nil) { [weak self] task in
            print("[BackgroundDataManager] Background refresh task triggered")
            self?.handleBackgroundRefreshTask(task as! BGAppRefreshTask)
        }
        
        // Register background processing task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: processingTaskIdentifier, using: nil) { [weak self] task in
            print("[BackgroundDataManager] Background processing task triggered")
            self?.handleBackgroundProcessingTask(task as! BGProcessingTask)
        }
    }
    
    private func scheduleBackgroundTasks() {
        // Cancel existing tasks
        BGTaskScheduler.shared.cancelAllTaskRequests()
        backgroundTasksScheduled = 0
        
        guard isBackgroundRefreshEnabled else {
            print("[BackgroundDataManager] Background refresh disabled - not scheduling tasks")
            return
        }
        
        // Schedule background app refresh
        let refreshRequest = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        refreshRequest.earliestBeginDate = Date(timeIntervalSinceNow: backgroundRefreshInterval)
        
        do {
            try BGTaskScheduler.shared.submit(refreshRequest)
            backgroundTasksScheduled += 1
            print("[BackgroundDataManager] Scheduled background refresh task")
        } catch {
            print("[BackgroundDataManager] Failed to schedule refresh task: \(error)")
        }
        
        // Schedule background processing task
        let processingRequest = BGProcessingTaskRequest(identifier: processingTaskIdentifier)
        processingRequest.earliestBeginDate = Date(timeIntervalSinceNow: backgroundRefreshInterval * 2)
        processingRequest.requiresNetworkConnectivity = true
        processingRequest.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(processingRequest)
            backgroundTasksScheduled += 1
            print("[BackgroundDataManager] Scheduled background processing task")
        } catch {
            print("[BackgroundDataManager] Failed to schedule processing task: \(error)")
        }
    }
    
    // MARK: - Background Task Handlers
    
    private func handleBackgroundRefreshTask(_ task: BGAppRefreshTask) {
        print("[BackgroundDataManager] Executing background refresh task")
        
        // Schedule next refresh
        scheduleBackgroundTasks()
        
        // Set completion handler
        task.expirationHandler = {
            print("[BackgroundDataManager] Background refresh task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform refresh
        Task {
            let success = await performDataRefresh()
            task.setTaskCompleted(success: success)
            print("[BackgroundDataManager] Background refresh completed: \(success)")
        }
    }
    
    private func handleBackgroundProcessingTask(_ task: BGProcessingTask) {
        print("[BackgroundDataManager] Executing background processing task")
        
        // Schedule next processing
        scheduleBackgroundTasks()
        
        // Set completion handler
        task.expirationHandler = {
            print("[BackgroundDataManager] Background processing task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform comprehensive data processing
        Task {
            let success = await performComprehensiveDataUpdate()
            task.setTaskCompleted(success: success)
            print("[BackgroundDataManager] Background processing completed: \(success)")
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchAndUpdateData(accessToken: String, accountID: String) async -> Bool {
        // Calculate date range for API calls
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        
        // Fetch AdSense data
        let adSenseResult = await AdSenseAPI.shared.fetchSummaryData(
            accountID: accountID,
            accessToken: accessToken,
            startDate: startDate,
            endDate: endDate
        )
        
        switch adSenseResult {
        case .success(let summaryData):
            // Convert to shared data model
            let sharedData = SharedSummaryData(from: summaryData)
            
            // Save to both legacy and new shared containers
            UserDefaultsManager.shared.saveSummaryData(summaryData)
            CrossPlatformDataBridge.shared.saveSharedSummaryData(sharedData)
            
            print("[BackgroundDataManager] Successfully updated AdSense data")
            return true
            
        case .failure(let error):
            print("[BackgroundDataManager] AdSense fetch failed: \(error)")
            return false
        }
    }
    
    private func performComprehensiveDataUpdate() async -> Bool {
        print("[BackgroundDataManager] Starting comprehensive data update...")
        
        // Perform regular data refresh
        let basicSuccess = await performDataRefresh()
        
        if basicSuccess {
            // Perform additional tasks like data cleanup, analytics, etc.
            await performMaintenanceTasks()
        }
        
        return basicSuccess
    }
    
    // MARK: - Target Updates
    
    private func updateAllTargets() async {
        print("[BackgroundDataManager] Updating all targets...")
        
        // Update widget
        await updateWidget()
        
        // Update watch app
        await updateWatchApp()
        
        // Trigger UI refresh in main app if active
        await refreshMainAppUI()
    }
    
    private func updateWidget() async {
        print("[BackgroundDataManager] Reloading widget timelines...")
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func updateWatchApp() async {
        // Load fresh data from shared container
        guard let sharedData = CrossPlatformDataBridge.shared.loadSharedSummaryData() else {
            print("[BackgroundDataManager] No shared data to send to watch")
            return
        }
        
        // Convert to legacy format for existing watch service
        let legacySummaryData = AdSenseSummaryData(
            today: sharedData.todayEarnings,
            yesterday: sharedData.yesterdayEarnings,
            last7Days: sharedData.last7DaysEarnings,
            thisMonth: sharedData.thisMonthEarnings,
            lastMonth: sharedData.lastMonthEarnings,
            lifetime: sharedData.lifetimeEarnings,
            todayDelta: sharedData.todayDelta,
            todayDeltaPositive: sharedData.todayDeltaPositive,
            yesterdayDelta: sharedData.yesterdayDelta,
            yesterdayDeltaPositive: sharedData.yesterdayDeltaPositive,
            last7DaysDelta: sharedData.last7DaysDelta,
            last7DaysDeltaPositive: sharedData.last7DaysDeltaPositive,
            thisMonthDelta: sharedData.thisMonthDelta,
            thisMonthDeltaPositive: sharedData.thisMonthDeltaPositive,
            lastMonthDelta: sharedData.lastMonthDelta,
            lastMonthDeltaPositive: sharedData.lastMonthDeltaPositive
        )
        
        // Send to watch via WatchDataSyncService
        WatchDataSyncService.shared.sendSummaryData(legacySummaryData)
        print("[BackgroundDataManager] Sent updated data to watch app")
    }
    
    private func refreshMainAppUI() async {
        // Post notification to refresh UI if app is active
        NotificationCenter.default.post(name: .backgroundDataUpdated, object: nil)
        print("[BackgroundDataManager] Posted UI refresh notification")
    }
    
    // MARK: - Utility Methods
    
    private func checkBackgroundRefreshStatus() {
        isBackgroundRefreshEnabled = UIApplication.shared.backgroundRefreshStatus == .available
        
        if let lastUpdate = UserDefaultsManager.shared.getDate(forKey: "lastBackgroundUpdate") {
            lastBackgroundUpdate = lastUpdate
        }
    }
    
    private func shouldPerformActiveRefresh() async -> Bool {
        guard let lastUpdate = lastBackgroundUpdate else { return true }
        
        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
        return timeSinceUpdate > appActiveRefreshInterval
    }
    
    private func performMaintenanceTasks() async {
        print("[BackgroundDataManager] Performing maintenance tasks...")
        
        // Clean up old cached data
        cleanupOldData()
        
        // Check memory usage
        let memoryPressure = MemoryManager.shared.checkMemoryPressure()
        if memoryPressure {
            print("[BackgroundDataManager] Memory cleanup performed during background update")
        }
    }
    
    private func cleanupOldData() {
        // Remove data older than 30 days (placeholder for future cleanup logic)
        let _ = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Add cleanup logic here if needed for cached historical data
        print("[BackgroundDataManager] Data cleanup completed")
    }
    
    // MARK: - Debug Information
    
    #if DEBUG
    func getDebugInfo() -> String {
        return """
        Background Data Manager Status:
        - Background Refresh: \(isBackgroundRefreshEnabled ? "Enabled" : "Disabled")
        - Last Update: \(lastBackgroundUpdate?.formatted() ?? "Never")
        - Scheduled Tasks: \(backgroundTasksScheduled)
        - System Background Status: \(UIApplication.shared.backgroundRefreshStatus.rawValue)
        """
    }
    
    /// Force background task execution for testing
    func simulateBackgroundTask() {
        Task {
            print("[BackgroundDataManager] Simulating background task...")
            let success = await performDataRefresh()
            print("[BackgroundDataManager] Simulated task result: \(success)")
        }
    }
    #endif
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let backgroundDataUpdated = Notification.Name("backgroundDataUpdated")
} 