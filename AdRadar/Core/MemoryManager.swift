import Foundation
import UIKit

/// Manages memory usage and provides utilities for memory optimization
class MemoryManager {
    static let shared = MemoryManager()
    
    private init() {
        setupMemoryWarnings()
    }
    
    // MARK: - Memory Warning Handling
    
    private func setupMemoryWarnings() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        print("[MemoryManager] Memory warning received - cleaning up caches")
        cleanupCaches()
    }
    
    // MARK: - Cache Management
    
    func cleanupCaches() {
        // Clear URLSession caches
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
        
        // Clear UserDefaults caches (if any)
        UserDefaults.standard.synchronize()
        
        // Force garbage collection if available
        #if DEBUG
        print("[MemoryManager] Cache cleanup completed")
        #endif
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
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
    
    func getMemoryUsageString() -> String {
        let bytes = getCurrentMemoryUsage()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    // MARK: - Performance Optimization
    
    func optimizeForLowMemory() {
        // Reduce image quality for better memory usage
        // This could be implemented based on available memory
        let memoryUsage = getCurrentMemoryUsage()
        let memoryThreshold: UInt64 = 100 * 1024 * 1024 // 100MB
        
        if memoryUsage > memoryThreshold {
            print("[MemoryManager] High memory usage detected: \(getMemoryUsageString())")
            cleanupCaches()
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 