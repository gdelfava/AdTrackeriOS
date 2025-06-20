import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: SummaryViewModel
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: 6)
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: SummaryViewModel(accessToken: nil))
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 24) {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    if viewModel.isOffline {
                        Text("No internet connection. Please check your network and try again.")
                            .foregroundColor(.red)
                            .padding()
                    }
                    if let lastUpdate = viewModel.lastUpdateTime {
                        Text("Last updated: \(lastUpdate.formatted(.relative(presentation: .named))) on \(lastUpdate.formatted(.dateTime.weekday(.wide)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading...")
                            .padding()
                        Spacer()
                    } else if let error = viewModel.error {
                        Spacer()
                        ErrorBannerView(message: error, symbol: errorSymbol(for: error))
                        Spacer()
                    } else if let data = viewModel.summaryData {
                        Group {
                            SummaryCardView(
                                title: "Today so far",
                                value: data.today,
                                subtitle: "vs yesterday",
                                delta: data.todayDelta,
                                deltaPositive: data.todayDeltaPositive,
                                onTap: { Task { await viewModel.fetchMetrics(forCard: .today) } }
                            )
                            .opacity(cardAppearances[0] ? 1 : 0)
                            .offset(y: cardAppearances[0] ? 0 : 20)
                            
                            SummaryCardView(
                                title: "Yesterday",
                                value: data.yesterday,
                                subtitle: "vs the same day last week",
                                delta: data.yesterdayDelta,
                                deltaPositive: data.yesterdayDeltaPositive,
                                onTap: { Task { await viewModel.fetchMetrics(forCard: .yesterday) } }
                            )
                            .opacity(cardAppearances[1] ? 1 : 0)
                            .offset(y: cardAppearances[1] ? 0 : 20)
                            
                            SummaryCardView(
                                title: "Last 7 Days",
                                value: data.last7Days,
                                subtitle: "vs the previous 7 days",
                                delta: data.last7DaysDelta,
                                deltaPositive: data.last7DaysDeltaPositive,
                                onTap: { Task { await viewModel.fetchMetrics(forCard: .last7Days) } }
                            )
                            .opacity(cardAppearances[2] ? 1 : 0)
                            .offset(y: cardAppearances[2] ? 0 : 20)
                            
                            SummaryCardView(
                                title: "This month",
                                value: data.thisMonth,
                                subtitle: "vs the same day last month",
                                delta: data.thisMonthDelta,
                                deltaPositive: data.thisMonthDeltaPositive,
                                onTap: { Task { await viewModel.fetchMetrics(forCard: .thisMonth) } }
                            )
                            .opacity(cardAppearances[3] ? 1 : 0)
                            .offset(y: cardAppearances[3] ? 0 : 20)
                            
                            SummaryCardView(
                                title: "Last month",
                                value: data.lastMonth,
                                subtitle: "vs the previous month",
                                delta: data.lastMonthDelta,
                                deltaPositive: data.lastMonthDeltaPositive,
                                onTap: { Task { await viewModel.fetchMetrics(forCard: .lastMonth) } }
                            )
                            .opacity(cardAppearances[4] ? 1 : 0)
                            .offset(y: cardAppearances[4] ? 0 : 20)
                            
                            SummaryCardView(
                                title: "Last three years",
                                value: data.lifetime,
                                subtitle: "AdRadar for Adsense",
                                delta: nil,
                                deltaPositive: nil,
                                onTap: { Task { await viewModel.fetchMetrics(forCard: .lastThreeYears) } }
                            )
                            .opacity(cardAppearances[5] ? 1 : 0)
                            .offset(y: cardAppearances[5] ? 0 : 20)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)
                        .onAppear {
                            // Animate cards when they appear
                            for i in 0..<cardAppearances.count {
                                withAnimation(.easeOut(duration: 0.5).delay(Double(i) * 0.1)) {
                                    cardAppearances[i] = true
                                }
                            }
                        }
                        .onDisappear {
                            // Reset animation state when view disappears
                            cardAppearances = Array(repeating: false, count: 6)
                        }
                        Spacer(minLength: 32)
                        Text("AdRadar is not affiliated with Google or Google AdSense. All data is provided by Google and is subject to their terms of service.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                    }
                }
                .padding(.top)
            }
            .refreshable {
                if let token = authViewModel.accessToken {
                    viewModel.accessToken = token
                    viewModel.authViewModel = authViewModel
                    await viewModel.fetchSummary()
                }
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSlideOverMenu = true
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
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
        .onAppear {
            if let token = authViewModel.accessToken, !viewModel.hasLoaded {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                Task { await viewModel.fetchSummary() }
            }
        }
        .overlay(
            Group {
                if viewModel.showOfflineToast {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("No internet connection")
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.85))
                                .cornerRadius(16)
                            Spacer()
                        }
                        .padding(.bottom, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: viewModel.showOfflineToast)
                }
            }
        )
        .sheet(isPresented: $viewModel.showNetworkErrorModal) {
            NetworkErrorModalView(
                message: "The Internet connection appears to be offline. Please check your Wi-Fi or Cellular settings.",
                onClose: { viewModel.showNetworkErrorModal = false },
                onSettings: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            )
        }
        .sheet(isPresented: $viewModel.showDayMetricsSheet) {
            if let metrics = viewModel.selectedDayMetrics {
                DayMetricsSheet(metrics: metrics, title: viewModel.selectedCardTitle)
            } else {
                ProgressView("Loading metrics...")
                    .padding()
            }
        }
    }
    
    // Helper to pick an SF Symbol for the error
    private func errorSymbol(for error: String) -> String {
        if error.localizedCaseInsensitiveContains("internet") || error.localizedCaseInsensitiveContains("offline") {
            return "wifi.slash"
        } else if error.localizedCaseInsensitiveContains("unauthorized") || error.localizedCaseInsensitiveContains("token") {
            return "key.slash"
        } else if error.localizedCaseInsensitiveContains("server") || error.localizedCaseInsensitiveContains("500") {
            return "server.rack"
        } else {
            return "exclamationmark.triangle"
        }
    }
}

struct SummaryCardView: View {
    let title: String
    let value: String
    let subtitle: String?
    let delta: String?
    let deltaPositive: Bool?
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    
    private var timeIcon: String {
        switch title.lowercased() {
        case let str where str.contains("today"):
            return "calendar.circle.fill"
        case let str where str.contains("yesterday"):
            return "calendar.badge.clock"
        case let str where str.contains("7 days"):
            return "calendar.badge.plus"
        case let str where str.contains("this month"):
            return "calendar"
        case let str where str.contains("last month"):
            return "calendar.badge.minus"
        case let str where str.contains("three years"), let str where str.contains("lifetime"):
            return "infinity.circle.fill"
        default:
            return "chart.bar.fill"
        }
    }
    
    private var iconColor: Color {
        switch title.lowercased() {
        case let str where str.contains("today"):
            return .green
        case let str where str.contains("yesterday"):
            return .orange
        case let str where str.contains("7 days"):
            return .blue
        case let str where str.contains("this month"):
            return .purple
        case let str where str.contains("last month"):
            return .pink
        case let str where str.contains("three years"), let str where str.contains("lifetime"):
            return .indigo
        default:
            return .accentColor
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Time period icon and title
                    HStack(spacing: 12) {
                        Image(systemName: timeIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(iconColor)
                            .frame(width: 32, height: 32)
                            .background(iconColor.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Tap indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Main value
                Text(value)
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // Delta indicator
                if let delta = delta, let positive = deltaPositive {
                    HStack(spacing: 8) {
                        Image(systemName: positive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(positive ? .green : .red)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(delta)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(positive ? .green : .red)
                        
                        Spacer()
                        
                        // Performance badge
                        Text(positive ? "Up" : "Down")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .textCase(.uppercase)
                            .foregroundColor(positive ? .green : .red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((positive ? Color.green : Color.red).opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding(20)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Animation
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            // Reset animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
            
            // Call the onTap closure
            onTap?()
        }
    }
}

struct DayMetricsSheet: View {
    let metrics: AdSenseDayMetrics
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: 3)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header section with enhanced styling
                        headerSection
                        
                        // Enhanced metric cards
                        VStack(spacing: 20) {
                            // Performance Card
                            EnhancedMetricCard(
                                title: "Engagement Metrics",
                                icon: "chart.bar.xaxis.ascending.badge.clock",
                                iconColor: .blue,
                                metrics: [
                                    MetricData(
                                        icon: "cursorarrow.click",
                                        title: "Clicks",
                                        value: metrics.clicks,
                                        subtitle: "User Interactions",
                                        color: .blue
                                    ),
                                    MetricData(
                                        icon: "eye.fill",
                                        title: "Impressions",
                                        value: metrics.impressions,
                                        subtitle: "Ad Views",
                                        color: .cyan
                                    ),
                                    MetricData(
                                        icon: "percent",
                                        title: "CTR",
                                        value: metrics.formattedImpressionsCTR,
                                        subtitle: "Click Rate",
                                        color: .indigo
                                    )
                                ]
                            )
                            .opacity(cardAppearances[0] ? 1 : 0)
                            .offset(y: cardAppearances[0] ? 0 : 30)
                            
                            // Traffic Card
                            EnhancedMetricCard(
                                title: "Traffic Analytics",
                                icon: "network.badge.shield.half.filled",
                                iconColor: .orange,
                                metrics: [
                                    MetricData(
                                        icon: "doc.text.fill",
                                        title: "Page Views",
                                        value: metrics.requests,
                                        subtitle: "Site Traffic",
                                        color: .orange
                                    ),
                                    MetricData(
                                        icon: "checkmark.circle.fill",
                                        title: "Matched Requests",
                                        value: metrics.matchedRequests,
                                        subtitle: "Ad Requests",
                                        color: .mint
                                    )
                                ]
                            )
                            .opacity(cardAppearances[1] ? 1 : 0)
                            .offset(y: cardAppearances[1] ? 0 : 30)
                            
                            // Cost Analysis Card
                            EnhancedMetricCard(
                                title: "Cost Analysis",
                                icon: "chart.pie.fill",
                                iconColor: .purple,
                                metrics: [
                                    MetricData(
                                        icon: "creditcard.fill",
                                        title: "Cost Per Click",
                                        value: metrics.formattedCostPerClick,
                                        subtitle: "Average CPC",
                                        color: .purple
                                    )
                                ]
                            )
                            .opacity(cardAppearances[2] ? 1 : 0)
                            .offset(y: cardAppearances[2] ? 0 : 30)
                        }
                        .padding(.horizontal, 20)
                        
                        // Footer disclaimer
                        Text("AdRadar is not affiliated with Google or Google AdSense. All data is provided by Google and is subject to their terms of service.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.body.weight(.medium))
                    .foregroundColor(.accentColor)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            // Stagger the card animations
            for index in 0..<cardAppearances.count {
                withAnimation(.easeOut(duration: 0.6).delay(Double(index) * 0.1)) {
                    cardAppearances[index] = true
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon or Branding Element
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(0.8),
                                Color.accentColor
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("Detailed Metrics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Comprehensive performance overview")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
    }
}

// Supporting structures and views
struct MetricData {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
}

struct EnhancedMetricCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let metrics: [MetricData]
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header section with enhanced styling
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    // Enhanced icon design
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        iconColor.opacity(0.15),
                                        iconColor.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Performance insights")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Metrics grid with improved layout
                if metrics.count == 1 {
                    // Single metric - full width
                    singleMetricView(metrics[0])
                } else {
                    // Multiple metrics - grid layout
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
                            metricPillView(metric)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 0.5)
        )
    }
    
    private func singleMetricView(_ metric: MetricData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: metric.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(metric.color)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(metric.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(metric.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(metric.value)
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private func metricPillView(_ metric: MetricData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: metric.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(metric.color)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(metric.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(metric.subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Text(metric.value)
                .font(.system(.callout, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    SummaryView(showSlideOverMenu: .constant(false), selectedTab: .constant(0))
}
