import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @EnvironmentObject private var premiumStatusManager: PremiumStatusManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingRestoreAlert = false
    @State private var isPurchasing = false
    @State private var selectedProductID: String?
    @State private var animateFloatingElements = false
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: 4)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background - consistent with SummaryView
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color.accentColor.opacity(0.1),
                        Color(.systemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                // Floating elements for visual interest
                PremiumFloatingElementsView(animate: $animateFloatingElements)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // TRIAL STATUS BANNER - Show if user is in trial
                        if premiumStatusManager.isInTrialPeriod {
                            trialStatusBanner
                                .padding(.horizontal, 20)
                                .padding(.top, 10)
                        }
                        
                        // HERO SECTION - Premium branding
                        VStack(spacing: 20) {
                            heroSection
                        }
                        .padding(.top, premiumStatusManager.isInTrialPeriod ? 20 : 40)
                        .padding(.horizontal, 20)
                        
                        // FEATURES SECTION
                        VStack(spacing: 16) {
                            SectionHeader(
                                title: "Pro Features", 
                                icon: "star.fill", 
                                color: .accentColor
                            )
                            
                            premiumFeaturesGrid
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        
                        // PRICING SECTION
                        VStack(spacing: 20) {
                            SectionHeader(
                                title: premiumStatusManager.isInTrialPeriod ? "Continue with Pro" : "Choose Your Plan", 
                                icon: "creditcard.fill", 
                                color: .green
                            )
                            
                            if storeManager.isLoading {
                                ProgressView("Loading plans...")
                                    .soraBody()
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 40)
                            } else if storeManager.products.isEmpty {
                                emptyProductsView
                            } else {
                                productsSection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        
                        // RESTORE SECTION
                        VStack(spacing: 12) {
                            Button("Restore Purchases") {
                                Task {
                                    await storeManager.restorePurchases()
                                    showingRestoreAlert = true
                                }
                            }
                            .soraBody()
                            .foregroundColor(.accentColor)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(12)
                            
                            Text("Restore your previous purchases")
                                .soraCaption()
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(premiumStatusManager.isInTrialPeriod ? "Free Trial Active" : "Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .soraBody()
                    .foregroundColor(.accentColor)
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
        .onAppear {
            // Animate floating elements
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.8)) {
                        animateFloatingElements = true
                    }
                }
            }
            
            // Animate cards
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
                await MainActor.run {
                    for i in 0..<cardAppearances.count {
                        withAnimation(.easeOut(duration: 0.6).delay(Double(i) * 0.1)) {
                            cardAppearances[i] = true
                        }
                    }
                }
            }
        }
    }
    
    private var trialStatusBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
                
                Text("Free Trial Active")
                    .soraSubheadline()
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Spacer()
                
                if premiumStatusManager.isTrialExpiringSoon() {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                }
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(premiumStatusManager.trialTimeRemaining())
                        .soraBody()
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("Continue enjoying all pro features")
                        .soraCaption()
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if premiumStatusManager.isTrialExpiringSoon() {
                Text("Your trial expires soon. Subscribe to continue using pro features.")
                    .soraCaption()
                    .foregroundColor(.orange)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.green.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Premium crown icon with background
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 8) {
                Text("Pro Upgrade")
                    .soraTitle()
                    .multilineTextAlignment(.center)
                
                Text("Unlock advanced analytics and get the most out of your AdSense and AdMob data")
                    .soraBody()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
    }
    
    private var premiumFeaturesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 16) {
            PremiumFeatureCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Advanced Analytics",
                description: "Detailed insights and performance trends",
                color: .blue
            )
            .opacity(cardAppearances[0] ? 1 : 0)
            .offset(y: cardAppearances[0] ? 0 : 20)
            
            PremiumFeatureCard(
                icon: "calendar.badge.clock",
                title: "Unlimited History",
                description: "Access all your historical data",
                color: .purple
            )
            .opacity(cardAppearances[1] ? 1 : 0)
            .offset(y: cardAppearances[1] ? 0 : 20)
            
            PremiumFeatureCard(
                icon: "bell.badge.fill",
                title: "Priority Support",
                description: "Get help when you need it most",
                color: .orange
            )
            .opacity(cardAppearances[2] ? 1 : 0)
            .offset(y: cardAppearances[2] ? 0 : 20)
            
            PremiumFeatureCard(
                icon: "eye.slash.fill",
                title: "Ad-Free",
                description: "Enjoy a clean, distraction-free interface",
                color: .green
            )
            .opacity(cardAppearances[3] ? 1 : 0)
            .offset(y: cardAppearances[3] ? 0 : 20)
        }
    }
    
    private var productsSection: some View {
        LazyVStack(spacing: 16) {
            // Sort products to show yearly first, then monthly
            ForEach(Array(storeManager.products.sorted { product1, product2 in
                // Yearly products first
                if product1.id.contains("yearly") && !product2.id.contains("yearly") {
                    return true
                } else if !product1.id.contains("yearly") && product2.id.contains("yearly") {
                    return false
                } else {
                    // If both are same type, maintain original order
                    return false
                }
            }.enumerated()), id: \.element.id) { index, product in
                PremiumProductCard(
                    product: product,
                    isPurchased: storeManager.isPurchased(product.id),
                    isPurchasing: isPurchasing && selectedProductID == product.id,
                    isRecommended: product.id.contains("yearly"),
                    onPurchase: {
                        await purchaseProduct(product)
                    }
                )
                .padding(.vertical, 4)
            }
        }
    }
    
    private var emptyProductsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            
            Text("Unable to Load Plans")
                .soraHeadline()
            
            Text("Please check your internet connection and try again.")
                .soraBody()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await storeManager.loadProducts()
                }
            }
            .soraBody()
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .cornerRadius(12)
        }
        .padding(.vertical, 40)
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

// MARK: - Premium Feature Card
struct PremiumFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with colored background
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .soraSubheadline()
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text(description)
                    .soraCaption()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Premium Product Card  
struct PremiumProductCard: View {
    let product: Product
    let isPurchased: Bool
    let isPurchasing: Bool
    let isRecommended: Bool
    let onPurchase: () async -> Void
    
    private var isSubscription: Bool {
        product.subscription != nil
    }
    
    private var hasTrialOffer: Bool {
        product.subscription?.introductoryOffer != nil
    }
    
    private var trialPeriod: String? {
        guard let intro = product.subscription?.introductoryOffer else { return nil }
        
        let period = intro.period
        let unit = period.unit
        let value = period.value
        
        switch unit {
        case .day:
            return value == 1 ? "1 Day" : "\(value) Days"
        case .week:
            return value == 1 ? "1 Week" : "\(value) Weeks"
        case .month:
            return value == 1 ? "1 Month" : "\(value) Months"
        case .year:
            return value == 1 ? "1 Year" : "\(value) Years"
        @unknown default:
            return nil
        }
    }
    
    private var displayPrice: String {
        if isPurchased {
            return "Active"
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
        VStack(spacing: 0) {
            // Header with recommendation badge - only show if not trial offer
            if isRecommended && !(hasTrialOffer && product.id.contains("yearly")) {
                HStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.green)
                            .frame(height: 24)
                        
                        Text("BEST VALUE")
                            .soraCaption2()
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
            
            // Trial Banner for yearly plan - replaces recommendation badge
            if hasTrialOffer && product.id.contains("yearly") {
                VStack(spacing: 0) {
                    // Best Value badge for trial
                    HStack {
                        Spacer()
                        Text("BEST VALUE")
                            .soraCaption2()
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    
                    // Trial content
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.green)
                            
                            Text("3-Day FREE Trial")
                                .soraSubheadline()
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text("Try all pro features for free, then \(displayPrice)/year")
                                .soraCaption()
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                }
            }
            
            // Main content
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    // Product title
                    HStack {
                        Text(product.displayName)
                            .soraSubheadline()
                            .fontWeight(.semibold)
                        
                        if isRecommended {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    // Subscription period
                    if let period = subscriptionPeriod {
                        Text(period)
                            .soraCaption()
                            .foregroundColor(.secondary)
                    }
                    
                    // Trial info for monthly (if any)
                    if hasTrialOffer && !product.id.contains("yearly"), let trial = trialPeriod {
                        Text("\(trial) Free Trial")
                            .soraCaption()
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                // Purchase button or status
                if isPurchased {
                    VStack(spacing: 4) {
                        Text("✓")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("Active")
                            .soraCaption()
                            .foregroundColor(.green)
                    }
                } else {
                    Button(action: {
                        Task {
                            await onPurchase()
                        }
                    }) {
                        VStack(spacing: 6) {
                            if isPurchasing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .frame(height: 20)
                            } else {
                                if hasTrialOffer && product.id.contains("yearly") {
                                    Text("Start Free Trial")
                                        .soraSubheadline()
                                        .fontWeight(.semibold)
                                } else {
                                    Text(displayPrice)
                                        .soraSubheadline()
                                }
                            }
                            
                            if !isPurchasing {
                                if hasTrialOffer && product.id.contains("yearly") {
                                    Text("Then \(displayPrice)/year")
                                        .soraCaption()
                                } else {
                                    Text("Subscribe")
                                        .soraCaption()
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: hasTrialOffer && product.id.contains("yearly") ? 
                                    [Color.green, Color.green.opacity(0.8)] :
                                    [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(isPurchasing)
                }
            }
            .padding(20)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    (isRecommended || (hasTrialOffer && product.id.contains("yearly"))) ? Color.green.opacity(0.3) : Color.gray.opacity(0.1), 
                    lineWidth: (isRecommended || (hasTrialOffer && product.id.contains("yearly"))) ? 2 : 1
                )
        )
        .shadow(
            color: Color.black.opacity(0.1), 
            radius: (isRecommended || (hasTrialOffer && product.id.contains("yearly"))) ? 8 : 4, 
            x: 0, 
            y: (isRecommended || (hasTrialOffer && product.id.contains("yearly"))) ? 4 : 2
        )
    }
}

// MARK: - Premium Floating Elements
struct PremiumFloatingElementsView: View {
    @Binding var animate: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Crown-themed floating elements
                Circle()
                    .fill(Color.accentColor.opacity(0.06))
                    .frame(width: 45, height: 45)
                    .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.2)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.0).delay(0.3), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.04))
                    .frame(width: 60, height: 60)
                    .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.15)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.5).delay(0.8), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 35, height: 35)
                    .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.6)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.2).delay(1.2), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.03))
                    .frame(width: 50, height: 50)
                    .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.7)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.8).delay(1.6), value: animate)
            }
        }
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    PremiumUpgradeView()
} 
