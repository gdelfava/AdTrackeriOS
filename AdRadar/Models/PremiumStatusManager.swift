import Foundation
import Combine
import StoreKit

@MainActor
class PremiumStatusManager: ObservableObject {
    static let shared = PremiumStatusManager()
    
    @Published var isPremiumUser: Bool = false
    @Published var hasRemovedAds: Bool = false
    @Published var premiumFeatures: Set<PremiumFeature> = []
    @Published var subscriptionStatus: SubscriptionStatus?
    
    private let storeKitManager = StoreKitManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum PremiumFeature: String, CaseIterable {
        case advancedAnalytics
        case unlimitedHistory
        case prioritySupport
        case adFree
        case exportData
        case customAlerts
        
        var displayName: String {
            switch self {
            case .advancedAnalytics:
                return "Advanced Analytics"
            case .unlimitedHistory:
                return "Unlimited History"
            case .prioritySupport:
                return "Priority Support"
            case .adFree:
                return "Ad-Free Experience"
            case .exportData:
                return "Export Data"
            case .customAlerts:
                return "Custom Alerts"
            }
        }
        
        var description: String {
            switch self {
            case .advancedAnalytics:
                return "Detailed insights and performance trends"
            case .unlimitedHistory:
                return "Access all historical data without limits"
            case .prioritySupport:
                return "Fast customer support and direct assistance"
            case .adFree:
                return "Remove all advertisements from the app"
            case .exportData:
                return "Export your data in multiple formats"
            case .customAlerts:
                return "Set custom notifications and alerts"
            }
        }
        
        var iconName: String {
            switch self {
            case .advancedAnalytics:
                return "chart.line.uptrend.xyaxis"
            case .unlimitedHistory:
                return "calendar"
            case .prioritySupport:
                return "bell.badge"
            case .adFree:
                return "eye.slash"
            case .exportData:
                return "square.and.arrow.up"
            case .customAlerts:
                return "bell.and.waves.left.and.right"
            }
        }
    }
    
    enum SubscriptionStatus {
        case active
        case expired
        case inGracePeriod
        case inBillingRetryPeriod
        case revoked
        case none
        
        var displayName: String {
            switch self {
            case .active:
                return "Active"
            case .expired:
                return "Expired"
            case .inGracePeriod:
                return "Grace Period"
            case .inBillingRetryPeriod:
                return "Billing Retry"
            case .revoked:
                return "Revoked"
            case .none:
                return "None"
            }
        }
        
        var isValid: Bool {
            switch self {
            case .active, .inGracePeriod, .inBillingRetryPeriod:
                return true
            case .expired, .revoked, .none:
                return false
            }
        }
    }
    
    private init() {
        setupObservers()
        updatePremiumStatus()
    }
    
    private func setupObservers() {
        // Listen to StoreKit manager changes
        storeKitManager.$purchasedProductIDs
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updatePremiumStatus()
                }
            }
            .store(in: &cancellables)
        
        storeKitManager.$subscriptionStatus
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.updatePremiumStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    func updatePremiumStatus() {
        // Check if user has active premium subscription
        isPremiumUser = storeKitManager.hasActivePremiumSubscription()
        
        // Check if user has removed ads
        hasRemovedAds = storeKitManager.hasRemovedAds()
        
        // Update premium features based on purchases
        updatePremiumFeatures()
        
        // Update subscription status
        updateSubscriptionStatus()
    }
    
    private func updatePremiumFeatures() {
        var features: Set<PremiumFeature> = []
        
        if isPremiumUser {
            // Premium subscription includes all features
            features = Set(PremiumFeature.allCases)
        } else {
            // Check individual purchases
            if storeKitManager.isPurchased("com.delteqis.adradar.pro_monthly") {
                features.insert(.adFree)
            }
        }
        
        premiumFeatures = features
    }
    
    private func updateSubscriptionStatus() {
        guard let renewalState = storeKitManager.subscriptionStatus else {
            subscriptionStatus = SubscriptionStatus.none
            return
        }
        
        // Check if subscription is revoked
        if renewalState.transaction.revocationDate != nil {
            subscriptionStatus = .revoked
        } else if renewalState.isActive {
            subscriptionStatus = .active
        } else {
            subscriptionStatus = .expired
        }
    }
    
    // MARK: - Feature Access Methods
    
    func hasFeature(_ feature: PremiumFeature) -> Bool {
        return premiumFeatures.contains(feature)
    }
    
    func canAccessAdvancedAnalytics() -> Bool {
        return hasFeature(.advancedAnalytics)
    }
    
    func canAccessUnlimitedHistory() -> Bool {
        return hasFeature(.unlimitedHistory)
    }
    
    func canAccessPrioritySupport() -> Bool {
        return hasFeature(.prioritySupport)
    }
    
    func shouldShowAds() -> Bool {
        return !hasFeature(.adFree)
    }
    
    func canExportData() -> Bool {
        return hasFeature(.exportData)
    }
    
    func canSetCustomAlerts() -> Bool {
        return hasFeature(.customAlerts)
    }
    
    // MARK: - Purchase Methods
    
    func purchasePremiumMonthly() async throws {
        guard let product = storeKitManager.products.first(where: { $0.id == "com.delteqis.adradar.premium_monthly_sub" }) else {
            throw StoreKitManager.StoreKitError.productNotAvailable
        }
        try await storeKitManager.purchase(product)
    }
    
    func purchasePremiumYearly() async throws {
        guard let product = storeKitManager.products.first(where: { $0.id == "com.delteqis.adradar.premium_yearly_sub" }) else {
            throw StoreKitManager.StoreKitError.productNotAvailable
        }
        try await storeKitManager.purchase(product)
    }
    
    func purchaseRemoveAds() async throws {
        guard let product = storeKitManager.products.first(where: { $0.id == "com.delteqis.adradar.pro_monthly" }) else {
            throw StoreKitManager.StoreKitError.productNotAvailable
        }
        try await storeKitManager.purchase(product)
    }
    
    func restorePurchases() async {
        await storeKitManager.restorePurchases()
    }
    
    // MARK: - Subscription Management
    
    var subscriptionExpirationDate: Date? {
        return storeKitManager.subscriptionStatus?.expirationDate
    }
    
    var willAutoRenew: Bool {
        return storeKitManager.subscriptionStatus?.willRenew ?? false
    }
    
    func openSubscriptionManagement() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            Task {
                try? await AppStore.showManageSubscriptions(in: windowScene)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func formattedSubscriptionStatus() -> String {
        guard let status = subscriptionStatus else { return "No subscription" }
        
        var statusText = status.displayName
        
        if let expirationDate = subscriptionExpirationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            statusText += " (expires: \(formatter.string(from: expirationDate)))"
        }
        
        return statusText
    }
    
    func shouldShowUpgradePrompt(for feature: PremiumFeature) -> Bool {
        return !hasFeature(feature) && !isPremiumUser
    }
    
    // MARK: - Usage Analytics
    
    func trackFeatureUsage(_ feature: PremiumFeature) {
        // Track feature usage for analytics
        #if DEBUG
        print("📊 Feature used: \(feature.displayName) - Access: \(hasFeature(feature) ? "Granted" : "Denied")")
        #endif
        
        // You can integrate with your analytics service here
        // Analytics.track("feature_usage", parameters: [
        //     "feature": feature.rawValue,
        //     "access_granted": hasFeature(feature),
        //     "is_premium": isPremiumUser
        // ])
    }
} 