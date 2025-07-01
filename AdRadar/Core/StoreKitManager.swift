import Foundation
import StoreKit
import Combine

@MainActor
public class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var subscriptionStatus: RenewalState?
    @Published var isLoading = false
    @Published var error: StoreKitError?
    
    private var updateListenerTask: Task<Void, Error>?
    private let productIdentifiers: Set<String> = [
        "com.delteqis.adradar.pro_monthly_sub",
        "com.delteqis.adradar.pro_yearly_sub"
    ]
    
    public enum StoreKitError: Error, LocalizedError {
        case failedVerification
        case unknownError
        case systemError(Error)
        case userCancelled
        case paymentNotAllowed
        case productNotAvailable
        
        public var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "Purchase verification failed"
            case .unknownError:
                return "An unknown error occurred"
            case .systemError(let error):
                return error.localizedDescription
            case .userCancelled:
                return "Purchase was cancelled"
            case .paymentNotAllowed:
                return "Payments are not allowed on this device"
            case .productNotAvailable:
                return "Product is not available"
            }
        }
    }
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        Task {
            // Load products and restore purchases
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        error = nil
        
        do {
            let storeProducts = try await Product.products(for: productIdentifiers)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            self.error = .systemError(error)
            print("Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase Handling
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            // Deliver content to the user
            await updatePurchasedProducts()
            
            // Always finish a transaction
            await transaction.finish()
            
        case .userCancelled:
            throw StoreKitError.userCancelled
            
        case .pending:
            // Transaction waiting on SCA (Strong Customer Authentication) or approval from a parent
            break
            
        @unknown default:
            throw StoreKitError.unknownError
        }
    }
    
    // MARK: - Transaction Verification
    
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Transaction Updates
    
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Iterate through any transactions that don't come from a direct call to `purchase()`
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // Deliver products to the user
                    await self.updatePurchasedProducts()
                    
                    // Always finish a transaction
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }
    
    // MARK: - Purchased Products
    
    @MainActor
    func updatePurchasedProducts() async {
        var purchasedProducts: Set<String> = []
        
        // Iterate through all unfinished transactions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                switch transaction.productType {
                case .nonConsumable:
                    purchasedProducts.insert(transaction.productID)
                default:
                    // For subscriptions and other types, check if not revoked
                    if transaction.revocationDate == nil {
                        purchasedProducts.insert(transaction.productID)
                    }
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        self.purchasedProductIDs = purchasedProducts
    }
    
    // MARK: - Subscription Status
    
    func updateSubscriptionStatus() async {
        do {
            guard let product = products.first(where: { $0.subscription != nil }),
                  let subscription = product.subscription else {
                return
            }
            
            let statuses = try await subscription.status
            
            var highestStatus: Product.SubscriptionInfo.Status?
            var highestRenewalState: RenewalState?
            
            for status in statuses {
                switch status.state {
                case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
                    let renewalInfo = try checkVerified(status.renewalInfo)
                    let transaction = try checkVerified(status.transaction)
                    
                    if highestStatus == nil {
                        highestStatus = status
                        highestRenewalState = RenewalState(
                            transaction: transaction,
                            renewalInfo: renewalInfo
                        )
                    }
                case .revoked, .expired:
                    continue
                default:
                    break
                }
            }
            
            subscriptionStatus = highestRenewalState
        } catch {
            print("Failed to update subscription status: \(error)")
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            self.error = .systemError(error)
        }
    }
    
    // MARK: - Helper Methods
    
    func isPurchased(_ productID: String) -> Bool {
        return purchasedProductIDs.contains(productID)
    }
    
    func hasActivePremiumSubscription() -> Bool {
        return isPurchased("com.delteqis.adradar.pro_monthly_sub") ||
               isPurchased("com.delteqis.adradar.pro_yearly_sub")
    }
    
    func hasRemovedAds() -> Bool {
        return isPurchased("com.delteqis.adradar.pro_monthly_sub") ||
               isPurchased("com.delteqis.adradar.pro_yearly_sub") ||
               hasActivePremiumSubscription()
    }
}

// MARK: - Supporting Types

public struct RenewalState {
    let transaction: Transaction
    let renewalInfo: Product.SubscriptionInfo.RenewalInfo
    
    var isActive: Bool {
        // Check if transaction is not revoked and hasn't expired
        guard transaction.revocationDate == nil else { return false }
        guard let expirationDate = transaction.expirationDate else { return true }
        return expirationDate > Date()
    }
    
    var willRenew: Bool {
        renewalInfo.willAutoRenew && transaction.revocationDate == nil
    }
    
    var expirationDate: Date? {
        transaction.expirationDate
    }
} 
