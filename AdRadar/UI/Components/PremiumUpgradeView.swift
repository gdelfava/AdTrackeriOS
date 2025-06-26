import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingRestoreAlert = false
    @State private var isPurchasing = false
    @State private var selectedProductID: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color.accentColor.opacity(0.1),
                        Color(.systemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        VStack(spacing: 16) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.accentColor)
                            
                            Text("Upgrade to Premium")
                                .soraTitle()
                                .multilineTextAlignment(.center)
                            
                            Text("Unlock advanced features and get the most out of AdRadar")
                                .soraBody()
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)
                        
                        // Features Section
                        premiumFeaturesSection
                        
                        // Products Section
                        if storeManager.isLoading {
                            ProgressView("Loading products...")
                                .soraBody()
                                .padding()
                        } else if storeManager.products.isEmpty {
                            Text("Unable to load products")
                                .soraBody()
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            productsSection
                        }
                        
                        // Restore Purchases Button
                        Button("Restore Purchases") {
                            Task {
                                await storeManager.restorePurchases()
                                showingRestoreAlert = true
                            }
                        }
                        .soraCaption()
                        .foregroundColor(.accentColor)
                        .padding(.top)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .soraBody()
                }
            }
            .alert("Restore Complete", isPresented: $showingRestoreAlert) {
                Button("OK") { }
            } message: {
                Text("Your purchases have been restored.")
            }
            .alert("Purchase Error", isPresented: .constant(storeManager.error != nil)) {
                Button("OK") {
                    storeManager.error = nil
                }
            } message: {
                Text(storeManager.error?.errorDescription ?? "An unknown error occurred")
            }
        }
    }
    
    private var premiumFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Premium Features")
                .soraHeadline()
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Advanced Analytics",
                    description: "Detailed insights and trends"
                )
                
                FeatureCard(
                    icon: "calendar",
                    title: "Unlimited History",
                    description: "Access all historical data"
                )
                
                FeatureCard(
                    icon: "bell.badge",
                    title: "Priority Support",
                    description: "Fast customer support"
                )
                
                FeatureCard(
                    icon: "eye.slash",
                    title: "Ad-Free Experience",
                    description: "Remove all advertisements"
                )
            }
            .padding(.horizontal)
        }
    }
    
    private var productsSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .soraHeadline()
                .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(storeManager.products, id: \.id) { product in
                    ProductRow(
                        product: product,
                        isPurchased: storeManager.isPurchased(product.id),
                        isPurchasing: isPurchasing && selectedProductID == product.id
                    ) {
                        await purchaseProduct(product)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func purchaseProduct(_ product: Product) async {
        guard !isPurchasing else { return }
        
        isPurchasing = true
        selectedProductID = product.id
        
        do {
            try await storeManager.purchase(product)
        } catch StoreKitManager.StoreKitError.userCancelled {
            // User cancelled, do nothing
        } catch {
            // Error is handled by the store manager
        }
        
        isPurchasing = false
        selectedProductID = nil
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30, height: 30)
            
            Text(title)
                .soraSubheadline()
                .multilineTextAlignment(.center)
            
            Text(description)
                .soraCaption()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ProductRow: View {
    let product: Product
    let isPurchased: Bool
    let isPurchasing: Bool
    let onPurchase: () async -> Void
    
    private var isSubscription: Bool {
        product.subscription != nil
    }
    
    private var displayPrice: String {
        if isPurchased {
            return "Purchased"
        }
        return product.displayPrice
    }
    
    private var subscriptionPeriod: String? {
        guard let subscription = product.subscription else { return nil }
        
        let unit = subscription.subscriptionPeriod.unit
        let value = subscription.subscriptionPeriod.value
        
        switch unit {
        case .day:
            return value == 1 ? "Daily" : "\(value) Days"
        case .week:
            return value == 1 ? "Weekly" : "\(value) Weeks"
        case .month:
            return value == 1 ? "Monthly" : "\(value) Months"
        case .year:
            return value == 1 ? "Yearly" : "\(value) Years"
        @unknown default:
            return nil
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .soraSubheadline()
                
                Text(product.description)
                    .soraCaption()
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let period = subscriptionPeriod {
                    Text(period)
                        .soraCaption()
                        .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            
            if isPurchased {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else {
                Button(action: {
                    Task {
                        await onPurchase()
                    }
                }) {
                    HStack(spacing: 4) {
                        if isPurchasing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text(displayPrice)
                                .soraSubheadline()
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(20)
                }
                .disabled(isPurchasing)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    PremiumUpgradeView()
} 