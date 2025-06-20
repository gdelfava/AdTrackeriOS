import SwiftUI

struct PaymentsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: PaymentsViewModel
    @Environment(\.colorScheme) private var uiColorScheme
    @State private var unpaidCardAppeared = false
    @State private var previousCardAppeared = false
    @State private var imageAppeared = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: PaymentsViewModel(accessToken: nil))
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading...")
                            .padding()
                        Spacer()
                    } else if let error = viewModel.error {
                        Spacer()
                        ErrorBannerView(message: error, symbol: errorSymbol(for: error))
                        Spacer()
                    } else if let data = viewModel.paymentsData {
                        VStack(alignment: .leading, spacing: 12) {
                            UnpaidEarningsCardView(
                                amount: data.unpaidEarnings,
                                date: data.previousPaymentDate,
                                isPaid: false // Set logic as needed
                            )
                            .opacity(unpaidCardAppeared ? 1 : 0)
                            .offset(y: unpaidCardAppeared ? 0 : 20)
                            
                            PreviousPaymentCardView(
                                amount: data.previousPaymentAmount,
                                date: data.previousPaymentDate
                            )
                            .opacity(previousCardAppeared ? 1 : 0)
                            .offset(y: previousCardAppeared ? 0 : 20)
                            
                            Image(uiColorScheme == .dark ? "moneyjumpblk2" : "moneyjumpwht2")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 330)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .opacity(imageAppeared ? 1 : 0)
                                .scaleEffect(imageAppeared ? 1 : 0.8)
                                .onAppear {
                                    // Animate unpaid card first
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        unpaidCardAppeared = true
                                    }
                                    
                                    // Animate previous payment card after delay
                                    withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                                        previousCardAppeared = true
                                    }
                                    
                                    // Animate image after cards
                                    withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                                        imageAppeared = true
                                    }
                                }
                                .onDisappear {
                                    // Reset animation states when view disappears
                                    unpaidCardAppeared = false
                                    previousCardAppeared = false
                                    imageAppeared = false
                                }
                            Spacer()
                        }
                        .padding(.horizontal)
                        Text("AdRadar is not affiliated with Google or Google AdSense. All data is provided by Google and is subject to their terms of service.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                    } else {
                    }
                }
                .padding(.top)
            }
            .background(Color(.systemBackground))
            .onAppear {
                if let token = authViewModel.accessToken, !viewModel.hasLoaded {
                    viewModel.accessToken = token
                    Task { await viewModel.fetchPayments() }
                }
            }
            .navigationTitle("Payments")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSlideOverMenu = true
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileImageView(url: authViewModel.userProfileImageURL)
                        .contextMenu {
                            Button(role: .destructive) {
                                authViewModel.signOut()
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                }
            }
        }
    }
    
    // Helper to pick an SF Symbol for the error
    private func errorSymbol(for error: String) -> String {
        if error.localizedCaseInsensitiveContains("internet") || error.localizedCaseInsensitiveContains("offline") {
            return "wifi.slash"
        } else if error.localizedCaseInsensitiveContains("unauthorized") || error.localizedCaseInsensitiveContains("session") {
            return "person.crop.circle.badge.exclamationmark"
        } else {
            return "exclamationmark.triangle"
        }
    }
}

struct PaymentCardView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct UnpaidEarningsCardView: View {
    let amount: String
    let date: String
    let isPaid: Bool
    
    @State private var isExpanded = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Earnings icon and status
                    HStack(spacing: 12) {
                        Image(systemName: "banknote.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.orange)
                            .frame(width: 32, height: 32)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unpaid Earnings")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Current Period")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status badge
                    Text(isPaid ? "Paid" : "Pending")
                        .font(.caption)
                        .fontWeight(.medium)
                        .textCase(.uppercase)
                        .foregroundColor(isPaid ? .green : .orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background((isPaid ? Color.green : Color.orange).opacity(0.1))
                        .clipShape(Capsule())
                }
                
                // Main amount
                Text(amount)
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // Main metrics pills
                HStack(spacing: 12) {
                    PaymentMetricPill(
                        icon: "clock.fill",
                        title: "Status",
                        value: isPaid ? "Paid" : "Pending",
                        color: isPaid ? .green : .orange
                    )
                    
                    PaymentMetricPill(
                        icon: "calendar.circle.fill",
                        title: "Period",
                        value: "Current",
                        color: .blue
                    )
                }
            }
            .padding(20)
            
            // Expandable detailed metrics
            if isExpanded {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        PaymentDetailedMetricRow(
                            icon: "calendar.badge.plus",
                            title: "Earnings Date",
                            value: date,
                            color: .blue
                        )
                        
                        PaymentDetailedMetricRow(
                            icon: "creditcard.fill",
                            title: "Payment Method",
                            value: "Bank Transfer",
                            color: .purple
                        )
                        
                        PaymentDetailedMetricRow(
                            icon: "building.2.fill",
                            title: "Payment Source",
                            value: "Google AdSense",
                            color: .green
                        )
                        
                        PaymentDetailedMetricRow(
                            icon: "info.circle.fill",
                            title: "Payment Info",
                            value: isPaid ? "Completed" : "Processing on next payment date",
                            color: .secondary
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color(.tertiarySystemBackground))
            }
            
            // Expand/Collapse button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Less Details" : "More Details")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.quaternarySystemFill))
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }
    }
}

struct PreviousPaymentCardView: View {
    let amount: String
    let date: String
    
    @State private var isExpanded = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Payment icon and info
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.green)
                            .frame(width: 32, height: 32)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Previous Payment")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Last Completed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Status badge
                    Text("Paid")
                        .font(.caption)
                        .fontWeight(.medium)
                        .textCase(.uppercase)
                        .foregroundColor(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                // Main amount
                Text(amount)
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // Main metrics pills
                HStack(spacing: 12) {
                    PaymentMetricPill(
                        icon: "checkmark.circle.fill",
                        title: "Status",
                        value: "Completed",
                        color: .green
                    )
                    
                    PaymentMetricPill(
                        icon: "calendar.badge.checkmark",
                        title: "Date",
                        value: "Last Period",
                        color: .blue
                    )
                }
            }
            .padding(20)
            
            // Expandable detailed metrics
            if isExpanded {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5)
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        PaymentDetailedMetricRow(
                            icon: "calendar.circle.fill",
                            title: "Payment Date",
                            value: date,
                            color: .blue
                        )
                        
                        PaymentDetailedMetricRow(
                            icon: "creditcard.fill",
                            title: "Payment Method",
                            value: "Bank Transfer",
                            color: .purple
                        )
                        
                        PaymentDetailedMetricRow(
                            icon: "building.2.fill",
                            title: "Payment Source",
                            value: "Google AdSense",
                            color: .green
                        )
                        
                        PaymentDetailedMetricRow(
                            icon: "clock.badge.checkmark.fill",
                            title: "Processing Time",
                            value: "Instant Transfer",
                            color: .orange
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(Color(.tertiarySystemBackground))
            }
            
            // Expand/Collapse button
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Less Details" : "More Details")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.quaternarySystemFill))
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }
    }
}

// Supporting components for payments
struct PaymentMetricPill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .frame(maxWidth: .infinity)
    }
}

struct PaymentDetailedMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 20, height: 20)
            
            Text(title)
                .font(.callout)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PaymentsView(showSlideOverMenu: .constant(false), selectedTab: .constant(0))
        .environmentObject(AuthViewModel())
}
