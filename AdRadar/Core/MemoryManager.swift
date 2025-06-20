import Foundation
import UIKit

/// Manages memory usage and provides utilities for memory optimization
class MemoryManager {
    static let shared = MemoryManager()
    
    private var memoryWarningCount = 0
    private let memoryThreshold: UInt64 = 150 * 1024 * 1024 // 150MB threshold
    
    private init() {
        setupMemoryWarnings()
        #if DEBUG
        print("[MemoryManager] Initialized with threshold: \(ByteCountFormatter().string(fromByteCount: Int64(memoryThreshold)))")
        #endif
    }
    
    // MARK: - Memory Warning Handling
    
    private func setupMemoryWarnings() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        memoryWarningCount += 1
        print("[MemoryManager] Memory warning #\(memoryWarningCount) received - performing selective cleanup")
        
        // Perform graduated cleanup based on warning count
        if memoryWarningCount == 1 {
            lightCleanup()
        } else if memoryWarningCount >= 2 {
            aggressiveCleanup()
        }
    }
    
    @objc private func handleDidEnterBackground() {
        // Perform cleanup when app enters background
        print("[MemoryManager] App entering background - performing cleanup")
        lightCleanup()
    }
    
    // MARK: - Graduated Cache Management
    
    private func lightCleanup() {
        // Clear only URL caches
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
        
        #if DEBUG
        print("[MemoryManager] Light cleanup completed - URL caches cleared")
        #endif
    }
    
    private func aggressiveCleanup() {
        // More aggressive cleanup for severe memory pressure
        lightCleanup()
        
        // Force UserDefaults synchronization
        UserDefaults.standard.synchronize()
        
        // Force a garbage collection hint (iOS will decide if appropriate)
        DispatchQueue.global(qos: .utility).async {
            // Intentionally empty - just creating GC pressure
        }
        
        #if DEBUG
        print("[MemoryManager] Aggressive cleanup completed")
        #endif
    }
    
    // MARK: - Public Cache Management
    
    func performMaintenanceCleanup() {
        // Safe cleanup method for regular maintenance
        lightCleanup()
        
        // Reset warning count after successful maintenance
        if memoryWarningCount > 0 {
            memoryWarningCount = max(0, memoryWarningCount - 1)
        }
    }
    
    // MARK: - Memory Usage Monitoring
    
    func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
    
    func getMemoryUsageString() -> String {
        let bytes = getCurrentMemoryUsage()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    func getMemoryPressureLevel() -> MemoryPressureLevel {
        let usage = getCurrentMemoryUsage()
        
        if usage == 0 {
            return .unknown
        } else if usage < memoryThreshold / 2 {
            return .normal
        } else if usage < memoryThreshold {
            return .warning
        } else {
            return .critical
        }
    }
    
    // MARK: - Performance Optimization
    
    func checkMemoryPressure() -> Bool {
        let pressureLevel = getMemoryPressureLevel()
        
        switch pressureLevel {
        case .warning:
            print("[MemoryManager] Memory pressure detected: \(getMemoryUsageString()) - performing light cleanup")
            lightCleanup()
            return true
        case .critical:
            print("[MemoryManager] Critical memory pressure: \(getMemoryUsageString()) - performing aggressive cleanup")
            aggressiveCleanup()
            return true
        case .normal, .unknown:
            return false
        }
    }
    
    // MARK: - Debug and Monitoring
    
    #if DEBUG
    func getDetailedMemoryInfo() -> String {
        let usageString = getMemoryUsageString()
        let pressureLevel = getMemoryPressureLevel()
        let warningCount = memoryWarningCount
        
        return """
        Current Usage: \(usageString)
        Pressure Level: \(pressureLevel)
        Warning Count: \(warningCount)
        Threshold: \(ByteCountFormatter().string(fromByteCount: Int64(memoryThreshold)))
        """
    }
    #endif
    
    // MARK: - Cleanup
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Supporting Types

enum MemoryPressureLevel: String, CaseIterable {
    case normal = "Normal"
    case warning = "Warning"
    case critical = "Critical"
    case unknown = "Unknown"
} 