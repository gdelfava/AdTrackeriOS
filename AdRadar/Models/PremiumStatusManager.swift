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
    @Published var isInTrialPeriod: Bool = false
    @Published var trialDaysRemaining: Int = 0
    @Published var trialExpiryDate: Date?
    
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
        case trial
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
            case .trial:
                return "Free Trial"
            case .none:
                return "None"
            }
        }
        
        var isValid: Bool {
            switch self {
            case .active, .inGracePeriod, .inBillingRetryPeriod, .trial:
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
        // Update trial status first
        updateTrialStatus()
        
        // Check if user has active premium subscription or is in trial
        isPremiumUser = storeKitManager.hasActivePremiumSubscription() || isInTrialPeriod
        
        // Check if user has removed ads
        hasRemovedAds = storeKitManager.hasRemovedAds() || isPremiumUser
        
        // Update premium features based on purchases
        updatePremiumFeatures()
        
        // Update subscription status
        updateSubscriptionStatus()
    }
    
    private func updateTrialStatus() {
        guard let renewalState = storeKitManager.subscriptionStatus else {
            isInTrialPeriod = false
            trialDaysRemaining = 0
            trialExpiryDate = nil
            return
        }
        
        // Check if this is a trial period
        let transaction = renewalState.transaction
        let _ = renewalState.renewalInfo // Acknowledge but don't use
        
        // Trial period is when:
        // 1. Transaction has an introductory offer
        // 2. User hasn't been charged yet (transaction amount is 0 or nil for trial)
        // 3. Subscription is active but hasn't converted to paid
        
        if let expirationDate = transaction.expirationDate {
            // purchaseDate is not optional in StoreKit 2
            let purchaseDate = transaction.purchaseDate
            
            // Check if this transaction represents a trial
            // For StoreKit 2, we need to check if the user is in the introductory offer period
            let timeInterval = expirationDate.timeIntervalSince(purchaseDate)
            let isTrialDuration = timeInterval <= (3 * 24 * 60 * 60 + 3600) // 3 days + 1 hour buffer
            
            if isTrialDuration && expirationDate > Date() {
                isInTrialPeriod = true
                trialExpiryDate = expirationDate
                trialDaysRemaining = max(0, Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0)
            } else {
                isInTrialPeriod = false
                trialDaysRemaining = 0
                trialExpiryDate = nil
            }
        } else {
            isInTrialPeriod = false
            trialDaysRemaining = 0
            trialExpiryDate = nil
        }
    }
    
    private func updatePremiumFeatures() {
        var features: Set<PremiumFeature> = []
        
        if isPremiumUser {
            // Premium subscription or trial includes all features
            features = Set(PremiumFeature.allCases)
        } else {
            // Check individual purchases (keeping existing logic for non-subscription purchases)
            if storeKitManager.isPurchased("com.delteqis.adradar.pro_monthly_sub") {
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
        } else if isInTrialPeriod {
            subscriptionStatus = .trial
        } else if renewalState.isActive {
            subscriptionStatus = .active
        } else {
            subscriptionStatus = .expired
        }
    }
    
    // MARK: - Feature Access Methods
    
    func hasFeature(_ feature: PremiumFeature) -> Bool {
        // Only bypass premium gates in demo mode
        if AuthViewModel.shared.isDemoMode {
            return true
        }
        // For real users, check if they have purchased the feature OR are in trial
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
        guard let product = storeKitManager.products.first(where: { $0.id == "com.delteqis.adradar.pro_monthly_sub" }) else {
            throw StoreKitManager.StoreKitError.productNotAvailable
        }
        try await storeKitManager.purchase(product)
    }
    
    func purchasePremiumYearly() async throws {
        guard let product = storeKitManager.products.first(where: { $0.id == "com.delteqis.adradar.pro_yearly_sub" }) else {
            throw StoreKitManager.StoreKitError.productNotAvailable
        }
        try await storeKitManager.purchase(product)
    }
    
    func purchaseRemoveAds() async throws {
        guard let product = storeKitManager.products.first(where: { $0.id == "com.delteqis.adradar.pro_monthly_sub" }) else {
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
    
    // MARK: - Trial Helper Methods
    
    func trialTimeRemaining() -> String {
        guard isInTrialPeriod, let expiryDate = trialExpiryDate else {
            return ""
        }
        
        let now = Date()
        let timeInterval = expiryDate.timeIntervalSince(now)
        
        if timeInterval <= 0 {
            return "Trial Expired"
        }
        
        let hours = Int(timeInterval) / 3600
        let days = hours / 24
        let remainingHours = hours % 24
        
        if days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") remaining"
        } else if remainingHours > 0 {
            return "\(remainingHours) hour\(remainingHours == 1 ? "" : "s") remaining"
        } else {
            let minutes = Int(timeInterval) / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s") remaining"
        }
    }
    
    func isTrialExpiringSoon() -> Bool {
        guard isInTrialPeriod, let expiryDate = trialExpiryDate else {
            return false
        }
        
        let timeRemaining = expiryDate.timeIntervalSince(Date())
        return timeRemaining <= (24 * 60 * 60) // 1 day
    }
    
    // MARK: - Helper Methods
    
    func formattedSubscriptionStatus() -> String {
        guard let status = subscriptionStatus else { return "No subscription" }
        
        // Determine which plan the user has
        var planText = ""
        if storeKitManager.isPurchased("com.delteqis.adradar.pro_yearly_sub") {
            planText = "Yearly Plan"
        } else if storeKitManager.isPurchased("com.delteqis.adradar.pro_monthly_sub") {
            planText = "Monthly Plan"
        } else {
            planText = status.displayName
        }
        
        // Add additional status information
        if isInTrialPeriod {
            return "\(planText) - \(trialTimeRemaining())"
        } else if let expirationDate = subscriptionExpirationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(planText) (expires: \(formatter.string(from: expirationDate)))"
        }
        
        return planText
    }
    
    func shouldShowUpgradePrompt(for feature: PremiumFeature) -> Bool {
        return !hasFeature(feature) && !isPremiumUser
    }
    
    func shouldShowTrialUpgradePrompt() -> Bool {
        return isInTrialPeriod && isTrialExpiringSoon()
    }
    
    // MARK: - Usage Analytics
    
    func trackFeatureUsage(_ feature: PremiumFeature) {
        // Track feature usage for analytics
        #if DEBUG
        print("📊 Feature used: \(feature.displayName) - Access: \(hasFeature(feature) ? "Granted" : "Denied") - Trial: \(isInTrialPeriod)")
        #endif
        
        // You can integrate with your analytics service here
        // Analytics.track("feature_usage", parameters: [
        //     "feature": feature.rawValue,
        //     "access_granted": hasFeature(feature),
        //     "is_premium": isPremiumUser,
        //     "is_trial": isInTrialPeriod,
        //     "trial_days_remaining": trialDaysRemaining
        // ])
    }
} 