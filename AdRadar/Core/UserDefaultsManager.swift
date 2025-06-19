import Foundation

/// Manages UserDefaults with proper app group handling and error recovery
class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    private let appGroupID = "group.com.delteqws.AdRadar"
    private var sharedDefaults: UserDefaults?
    private var standardDefaults: UserDefaults
    
    private init() {
        self.standardDefaults = UserDefaults.standard
        
        // Initialize shared UserDefaults with error handling
        if let shared = UserDefaults(suiteName: appGroupID) {
            self.sharedDefaults = shared
            print("[UserDefaultsManager] Successfully initialized shared UserDefaults")
        } else {
            print("[UserDefaultsManager] Warning: Failed to initialize shared UserDefaults, falling back to standard")
            self.sharedDefaults = nil
        }
    }
    
    // MARK: - Shared Container Methods
    
    func setValue(_ value: Any?, forKey key: String) {
        if let shared = sharedDefaults {
            shared.set(value, forKey: key)
            shared.synchronize()
        } else {
            // Fallback to standard UserDefaults
            standardDefaults.set(value, forKey: key)
            standardDefaults.synchronize()
        }
    }
    
    func getValue(forKey key: String) -> Any? {
        if let shared = sharedDefaults {
            return shared.object(forKey: key)
        } else {
            return standardDefaults.object(forKey: key)
        }
    }
    
    func removeValue(forKey key: String) {
        if let shared = sharedDefaults {
            shared.removeObject(forKey: key)
            shared.synchronize()
        } else {
            standardDefaults.removeObject(forKey: key)
            standardDefaults.synchronize()
        }
    }
    
    // MARK: - Type-Specific Methods
    
    func setString(_ value: String?, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    func getString(forKey key: String) -> String? {
        return getValue(forKey: key) as? String
    }
    
    func setData(_ value: Data?, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    func getData(forKey key: String) -> Data? {
        return getValue(forKey: key) as? Data
    }
    
    func setDate(_ value: Date?, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    func getDate(forKey key: String) -> Date? {
        return getValue(forKey: key) as? Date
    }
    
    func setBool(_ value: Bool, forKey key: String) {
        setValue(value, forKey: key)
    }
    
    func getBool(forKey key: String) -> Bool {
        return getValue(forKey: key) as? Bool ?? false
    }
    
    // MARK: - Summary Data Methods
    
    func saveSummaryData(_ summary: AdSenseSummaryData) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(summary) {
            setData(encoded, forKey: "summaryData")
            setDate(Date(), forKey: "summaryLastUpdate")
            print("[UserDefaultsManager] Successfully saved summary data")
        } else {
            print("[UserDefaultsManager] Failed to encode summary data")
        }
    }
    
    func loadSummaryData() -> AdSenseSummaryData? {
        guard let data = getData(forKey: "summaryData") else {
            print("[UserDefaultsManager] No summary data found")
            return nil
        }
        
        let decoder = JSONDecoder()
        if let summary = try? decoder.decode(AdSenseSummaryData.self, from: data) {
            print("[UserDefaultsManager] Successfully loaded summary data")
            return summary
        } else {
            print("[UserDefaultsManager] Failed to decode summary data")
            return nil
        }
    }
    
    func getLastUpdateDate() -> Date? {
        return getDate(forKey: "summaryLastUpdate")
    }
    
    // MARK: - Health Check
    
    func isSharedContainerAvailable() -> Bool {
        return sharedDefaults != nil
    }
    
    func resetSharedContainer() {
        sharedDefaults = UserDefaults(suiteName: appGroupID)
        print("[UserDefaultsManager] Attempted to reset shared container")
    }
} 