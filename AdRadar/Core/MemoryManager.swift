import Foundation
import UIKit

/// Manages memory usage and provides utilities for memory optimization
class MemoryManager {
    static let shared = MemoryManager()
    
    private var memoryWarningCount = 0
    private let memoryThreshold: UInt64 = 150 * 1024 * 1024 // 150MB threshold
    private let imageCache = NSCache<NSString, UIImage>()
    private var fontCache: [String: UIFont] = [:]
    private var monitoringTimer: Timer?
    
    private init() {
        setupMemoryWarnings()
        configureImageCache()
        startMemoryMonitoring()
        #if DEBUG
        print("[MemoryManager] Initialized with threshold: \(ByteCountFormatter().string(fromByteCount: Int64(memoryThreshold)))")
        logInitialMemoryUsage()
        #endif
    }
    
    // MARK: - Image Cache Configuration
    
    private func configureImageCache() {
        // Set reasonable cache limits to prevent memory bloat
        imageCache.countLimit = 50 // Max 50 images
        imageCache.totalCostLimit = 100 * 1024 * 1024 // Max 100MB for images
        
        // Auto-remove images under memory pressure
        imageCache.evictsObjectsWithDiscardedContent = true
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
        // Clear only URL caches and some image cache
        URLSession.shared.configuration.urlCache?.removeAllCachedResponses()
        
        // Remove half of cached images
        if imageCache.countLimit > 10 {
            imageCache.countLimit = max(10, imageCache.countLimit / 2)
        }
        
        #if DEBUG
        print("[MemoryManager] Light cleanup completed - URL caches cleared, image cache reduced")
        #endif
    }
    
    private func aggressiveCleanup() {
        // More aggressive cleanup for severe memory pressure
        lightCleanup()
        
        // Clear all image cache
        imageCache.removeAllObjects()
        imageCache.countLimit = 10
        
        // Clear font cache except essential fonts
        let essentialFonts = ["Sora-Regular", "Sora-Medium", "Sora-SemiBold"]
        fontCache = fontCache.filter { essentialFonts.contains($0.key) }
        
        // Force UserDefaults synchronization
        UserDefaults.standard.synchronize()
        
        #if DEBUG
        print("[MemoryManager] Aggressive cleanup completed - all caches cleared")
        #endif
    }
    
    // MARK: - Image Management
    
    func optimizedImage(named: String) -> UIImage? {
        let cacheKey = NSString(string: named)
        
        // Check cache first
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            return cachedImage
        }
        
        // Load and optimize image
        guard let originalImage = UIImage(named: named) else { return nil }
        
        // Compress large images
        let optimizedImage = compressImageIfNeeded(originalImage)
        
        // Cache the optimized version
        let cost = Int(optimizedImage.size.width * optimizedImage.size.height * 4) // Estimate bytes
        imageCache.setObject(optimizedImage, forKey: cacheKey, cost: cost)
        
        return optimizedImage
    }
    
    private func compressImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024
        
        // Check if image is too large
        guard image.size.width > maxDimension || image.size.height > maxDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = image.size.width / image.size.height
        var newSize: CGSize
        
        if image.size.width > image.size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // MARK: - Font Management
    
    func optimizedFont(name: String, size: CGFloat) -> UIFont? {
        let cacheKey = "\(name)-\(size)"
        
        if let cachedFont = fontCache[cacheKey] {
            return cachedFont
        }
        
        guard let font = UIFont(name: name, size: size) else {
            return UIFont.systemFont(ofSize: size) // Fallback
        }
        
        // Cache only if we have space
        if fontCache.count < 20 {
            fontCache[cacheKey] = font
        }
        
        return font
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
    
    func clearImageCache() {
        imageCache.removeAllObjects()
        print("[MemoryManager] Image cache cleared")
    }
    
    func clearFontCache() {
        fontCache.removeAll()
        print("[MemoryManager] Font cache cleared")
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
    
    // MARK: - Memory Monitoring
    
    private func startMemoryMonitoring() {
        // Check memory every 30 seconds
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            DispatchQueue.global(qos: .utility).async {
                _ = self?.checkMemoryPressure()
            }
        }
    }
    
    private func stopMemoryMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    // MARK: - Performance Optimization
    
    func checkMemoryPressure() -> Bool {
        let currentUsage = getCurrentMemoryUsage()
        let currentUsageMB = Double(currentUsage) / (1024 * 1024)
        let thresholdMB = Double(memoryThreshold) / (1024 * 1024)
        let criticalThreshold = memoryThreshold + (memoryThreshold / 2) // 1.5x threshold
        
        // Enhanced logging for tracking patterns
        let timestamp = DateFormatter()
        timestamp.dateFormat = "HH:mm:ss"
        let timeString = timestamp.string(from: Date())
        
        print("[MemoryManager] [\(timeString)] Current: \(String(format: "%.1f", currentUsageMB)) MB, Threshold: \(String(format: "%.1f", thresholdMB)) MB")
        
        if currentUsage > criticalThreshold {
            print("🚨 [MemoryManager] CRITICAL: \(String(format: "%.1f", currentUsageMB)) MB - performing aggressive cleanup")
            aggressiveCleanup()
            
            // Check if cleanup was effective
            let afterCleanup = getCurrentMemoryUsage()
            let afterCleanupMB = Double(afterCleanup) / (1024 * 1024)
            let reduction = currentUsageMB - afterCleanupMB
            print("✅ [MemoryManager] Aggressive cleanup: \(String(format: "%.1f", afterCleanupMB)) MB (reduced by \(String(format: "%.1f", reduction)) MB)")
            return true
            
        } else if currentUsage > memoryThreshold {
            print("⚠️ [MemoryManager] HIGH: \(String(format: "%.1f", currentUsageMB)) MB - performing light cleanup")
            lightCleanup()
            
            let afterCleanup = getCurrentMemoryUsage()
            let afterCleanupMB = Double(afterCleanup) / (1024 * 1024)
            let reduction = currentUsageMB - afterCleanupMB
            print("✅ [MemoryManager] Light cleanup: \(String(format: "%.1f", afterCleanupMB)) MB (reduced by \(String(format: "%.1f", reduction)) MB)")
            return true
        }
        
        return false
    }
    
    // MARK: - Debug and Monitoring
    
    #if DEBUG
    func logInitialMemoryUsage() {
        let usage = getCurrentMemoryUsage()
        let usageMB = Double(usage) / (1024 * 1024)
        print("[MemoryManager] Initial memory usage: \(String(format: "%.1f", usageMB)) MB")
        
        // Warn if initial usage is high
        if usageMB > 200 {
            print("⚠️ [MemoryManager] High initial memory usage detected! Consider optimizing assets.")
        }
    }
    
    func getDetailedMemoryInfo() -> String {
        let usageString = getMemoryUsageString()
        let pressureLevel = getMemoryPressureLevel()
        let warningCount = memoryWarningCount
        let imageCacheInfo = "Images: \(imageCache.countLimit) max, \(fontCache.count) fonts cached"
        
        return """
        Current Usage: \(usageString)
        Pressure Level: \(pressureLevel)
        Warning Count: \(warningCount)
        Cache Info: \(imageCacheInfo)
        Threshold: \(ByteCountFormatter().string(fromByteCount: Int64(memoryThreshold)))
        """
    }
    #endif
    
    // MARK: - Cleanup
    
    deinit {
        stopMemoryMonitoring()
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