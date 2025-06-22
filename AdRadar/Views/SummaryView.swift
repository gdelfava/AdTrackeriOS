import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: SummaryViewModel
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: 6)
    @State private var animateFloatingElements = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: SummaryViewModel(accessToken: nil))
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background - always full screen
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
                SummaryFloatingElementsView(animate: $animateFloatingElements)
                
                ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .soraBody()
                            .foregroundColor(.red)
                            .padding()
                    }
                    if viewModel.isOffline {
                        Text("No internet connection. Please check your network and try again.")
                            .soraBody()
                            .foregroundColor(.red)
                            .padding()
                    }

                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading...")
                            .soraBody()
                            .padding()
                        Spacer()
                    } else if let error = viewModel.error {
                        Spacer()
                        ErrorBannerView(message: error, symbol: errorSymbol(for: error))
                        Spacer()
                    } else if let data = viewModel.summaryData {
                        LazyVStack(spacing: 24) {
                            // HERO SECTION - Today's performance
                            VStack(spacing: 16) {
                                HeroSectionHeader(lastUpdateTime: viewModel.lastUpdateTime)
                                    .padding(.horizontal, 20)
                                
                                HeroSummaryCard(
                                    title: "Today So Far",
                                    value: data.today,
                                    subtitle: "vs yesterday",
                                    delta: data.todayDelta,
                                    deltaPositive: data.todayDeltaPositive,
                                    onTap: { Task { await viewModel.fetchMetrics(forCard: .today) } }
                                )
                                .opacity(cardAppearances[0] ? 1 : 0)
                                .offset(y: cardAppearances[0] ? 0 : 30)
                                .padding(.horizontal, 16)
                            }
                            .padding(.top, 8)
                            
                            // RECENT SECTION - Yesterday & Last 7 Days
                            VStack(spacing: 16) {
                                SectionHeader(title: "Recent Performance", icon: "clock.fill", color: .orange)
                                
                                VStack(spacing: 12) {
                                    CompactSummaryCard(
                                        title: "Yesterday",
                                        value: data.yesterday,
                                        subtitle: "vs the same day last week",
                                        delta: data.yesterdayDelta,
                                        deltaPositive: data.yesterdayDeltaPositive,
                                        icon: "calendar.badge.clock",
                                        color: .orange,
                                        onTap: { Task { await viewModel.fetchMetrics(forCard: .yesterday) } }
                                    )
                                    .opacity(cardAppearances[1] ? 1 : 0)
                                    .offset(y: cardAppearances[1] ? 0 : 20)
                                    
                                    CompactSummaryCard(
                                        title: "Last 7 Days",
                                        value: data.last7Days,
                                        subtitle: "vs the previous 7 days",
                                        delta: data.last7DaysDelta,
                                        deltaPositive: data.last7DaysDeltaPositive,
                                        icon: "calendar.badge.plus",
                                        color: .blue,
                                        onTap: { Task { await viewModel.fetchMetrics(forCard: .last7Days) } }
                                    )
                                    .opacity(cardAppearances[2] ? 1 : 0)
                                    .offset(y: cardAppearances[2] ? 0 : 20)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // MONTHLY SECTION - This month & Last month
                            VStack(spacing: 16) {
                                SectionHeader(title: "Monthly Overview", icon: "calendar.circle.fill", color: .purple)
                                
                                HStack(spacing: 12) {
                                    MonthlyCompactCard(
                                        title: "This Month",
                                        value: data.thisMonth,
                                        subtitle: "vs same day last month",
                                        delta: data.thisMonthDelta,
                                        deltaPositive: data.thisMonthDeltaPositive,
                                        icon: "calendar",
                                        color: .purple,
                                        onTap: { Task { await viewModel.fetchMetrics(forCard: .thisMonth) } }
                                    )
                                    .opacity(cardAppearances[3] ? 1 : 0)
                                    .offset(y: cardAppearances[3] ? 0 : 20)
                                    
                                    MonthlyCompactCard(
                                        title: "Last Month",
                                        value: data.lastMonth,
                                        subtitle: "vs previous month",
                                        delta: data.lastMonthDelta,
                                        deltaPositive: data.lastMonthDeltaPositive,
                                        icon: "calendar.badge.minus",
                                        color: .pink,
                                        onTap: { Task { await viewModel.fetchMetrics(forCard: .lastMonth) } }
                                    )
                                    .opacity(cardAppearances[4] ? 1 : 0)
                                    .offset(y: cardAppearances[4] ? 0 : 20)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // LIFETIME SECTION - All time performance
                            VStack(spacing: 16) {
                                SectionHeader(title: "All Time", icon: "infinity.circle.fill", color: .indigo)
                                
                                LifetimeSummaryCard(
                                    title: "Last Three Years",
                                    value: data.lifetime,
                                    subtitle: "AdRadar for Adsense",
                                    onTap: { Task { await viewModel.fetchMetrics(forCard: .lastThreeYears) } }
                                )
                                .opacity(cardAppearances[5] ? 1 : 0)
                                .offset(y: cardAppearances[5] ? 0 : 20)
                            }
                            .padding(.horizontal, 20)
                        }
                        .onAppear {
                            // Animate cards when they appear
                            for i in 0..<cardAppearances.count {
                                withAnimation(.easeOut(duration: 0.6).delay(Double(i) * 0.1)) {
                                    cardAppearances[i] = true
                                }
                            }
                        }
                        .onDisappear {
                            // Reset animation state when view disappears
                            cardAppearances = Array(repeating: false, count: 6)
                        }
                        
                        // Footer
                        VStack(spacing: 12) {
                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 0.5)
                                .padding(.horizontal, 20)
                            
                            Text("AdRadar is not affiliated with Google or Google AdSense.")
                                .soraFootnote()
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                        }
                        .padding(.top, 32)
                    }
                }
                .padding(.top, 20)
                }
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
            // Only fetch data on first load, not on every tab switch
            if let token = authViewModel.accessToken, !viewModel.hasLoaded {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                Task { await viewModel.fetchSummary() }
            }
            
            // Animate floating elements
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateFloatingElements = true
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
                                .soraBody()
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
        .fullScreenCover(isPresented: $viewModel.showDayMetricsSheet) {
            if let metrics = viewModel.selectedDayMetrics {
                DayMetricsSheet(metrics: metrics, title: viewModel.selectedCardTitle)
            } else {
                ProgressView("Loading metrics...")
                    .soraBody()
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

// MARK: - Hero Section Components

struct HeroSectionHeader: View {
    let lastUpdateTime: Date?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Performance")
                    .soraTitle2()
                    .foregroundColor(.primary)
                
                if let lastUpdate = lastUpdateTime {
                    Text("Last updated: \(lastUpdate.formatted(.relative(presentation: .named))) on \(lastUpdate.formatted(.dateTime.weekday(.wide)))")
                        .soraCaption()
                        .foregroundColor(.secondary)
                } else {
                    Text("Fetching latest data...")
                        .soraCaption()
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

struct HeroSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let delta: String?
    let deltaPositive: Bool?
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content
            VStack(alignment: .leading, spacing: 20) {
                // Header with icon
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.green.opacity(0.2),
                                            Color.green.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "calendar.circle.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.green)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .soraTitle3()
                                .foregroundColor(.primary)
                            
                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .soraCaption()
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Main value
                VStack(alignment: .leading, spacing: 12) {
                    Text(value)
                        .soraFont(.bold, size: 36)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    // Delta indicator with improved layout
                    if let delta = delta, let positive = deltaPositive {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Image(systemName: positive ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                                    .foregroundColor(positive ? .green : .red)
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text(delta)
                                    .soraSubheadline()
                                    .foregroundColor(positive ? .green : .red)
                                
                                Spacer()
                            }
                            
                            Text("compared to yesterday")
                                .soraCaption()
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill((positive ? Color.green : Color.red).opacity(0.1))
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.green.opacity(0.08), location: 0),
                        .init(color: Color.green.opacity(0.04), location: 0.5),
                        .init(color: Color.green.opacity(0.02), location: 1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Pattern overlay
                PatternOverlay(color: .green.opacity(0.03))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.green.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 20, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(0.2),
                            Color.clear,
                            Color.green.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
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
            
            onTap?()
        }
    }
}

// MARK: - Section Components

struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            Text(title)
                .soraHeadline()
                .foregroundColor(.primary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            
            Spacer(minLength: 8)
            
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
                .frame(maxWidth: 120)
        }
    }
}

struct CompactSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let delta: String?
    let deltaPositive: Bool?
    let icon: String
    let color: Color
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .soraSubheadline()
                    .foregroundColor(.primary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .soraCaption2()
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Value and delta
            VStack(alignment: .trailing, spacing: 4) {
                Text(value)
                    .soraTitle3()
                    .foregroundColor(.primary)
                
                if let delta = delta, let positive = deltaPositive {
                    HStack(spacing: 4) {
                        Image(systemName: positive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(positive ? .green : .red)
                        
                        Text(delta)
                            .soraCaption2()
                            .foregroundColor(positive ? .green : .red)
                    }
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
            
            onTap?()
        }
    }
}

struct MonthlyCompactCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let delta: String?
    let deltaPositive: Bool?
    let icon: String
    let color: Color
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .soraSubheadline()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(value)
                    .soraTitle3()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let delta = delta, let positive = deltaPositive {
                    HStack(spacing: 4) {
                        Image(systemName: positive ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(positive ? .green : .red)
                        
                        Text(delta)
                            .soraCaption2()
                            .foregroundColor(positive ? .green : .red)
                    }
                } else {
                    // Spacer to maintain consistent height
                    Text(" ")
                        .soraCaption2()
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: color.opacity(0.08), location: 0),
                    .init(color: color.opacity(0.04), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .scaleEffect(isPressed ? 0.96 : 1.0)
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
            
            onTap?()
        }
    }
}

struct LifetimeSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String?
    var onTap: (() -> Void)? = nil
    
    @State private var isPressed = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.indigo.opacity(0.2),
                                            Color.indigo.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "infinity.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.indigo)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .soraHeadline()
                                .foregroundColor(.primary)
                            
                            if let subtitle = subtitle {
                                Text(subtitle)
                                    .soraCaption()
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                // Value
                Text(value)
                    .soraFont(.bold, size: 28)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
        }
        .background(
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.indigo.opacity(0.1), location: 0),
                        .init(color: Color.indigo.opacity(0.05), location: 0.7),
                        .init(color: Color.indigo.opacity(0.02), location: 1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                PatternOverlay(color: .indigo.opacity(0.02))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.indigo.opacity(colorScheme == .dark ? 0.2 : 0.1), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.indigo.opacity(0.1), lineWidth: 1)
        )
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
            
            onTap?()
        }
    }
}

// MARK: - Supporting Views

struct PatternOverlay: View {
    let color: Color
    
    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 20
            let dotSize: CGFloat = 2
            
            for x in stride(from: 0, through: size.width, by: spacing) {
                for y in stride(from: 0, through: size.height, by: spacing) {
                    let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
    }
}

// MARK: - Legacy Card View (keeping for compatibility)

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
    
    private var cardGradient: LinearGradient {
        switch title.lowercased() {
        case let str where str.contains("today"):
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.green.opacity(0.15), location: 0),
                    .init(color: Color.green.opacity(0.08), location: 0.7),
                    .init(color: Color.green.opacity(0.03), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let str where str.contains("yesterday"):
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.orange.opacity(0.15), location: 0),
                    .init(color: Color.orange.opacity(0.08), location: 0.7),
                    .init(color: Color.orange.opacity(0.03), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let str where str.contains("7 days"):
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.blue.opacity(0.15), location: 0),
                    .init(color: Color.blue.opacity(0.08), location: 0.7),
                    .init(color: Color.blue.opacity(0.03), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let str where str.contains("this month"):
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.purple.opacity(0.15), location: 0),
                    .init(color: Color.purple.opacity(0.08), location: 0.7),
                    .init(color: Color.purple.opacity(0.03), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let str where str.contains("last month"):
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.pink.opacity(0.15), location: 0),
                    .init(color: Color.pink.opacity(0.08), location: 0.7),
                    .init(color: Color.pink.opacity(0.03), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case let str where str.contains("three years"), let str where str.contains("lifetime"):
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.indigo.opacity(0.15), location: 0),
                    .init(color: Color.indigo.opacity(0.08), location: 0.7),
                    .init(color: Color.indigo.opacity(0.03), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.accentColor.opacity(0.15), location: 0),
                    .init(color: Color.accentColor.opacity(0.08), location: 0.7),
                    .init(color: Color.accentColor.opacity(0.03), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                        
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Subtitle moved to top right
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Main value with chevron
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(value)
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        // Delta indicator (moved below value)
                        if let delta = delta, let positive = deltaPositive {
                            HStack(spacing: 6) {
                                Image(systemName: positive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundColor(positive ? .green : .red)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text(delta)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(positive ? .green : .red)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
        }
        .background(cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        .shadow(color: iconColor.opacity(0.08), radius: 20, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            iconColor.opacity(0.1),
                            Color.clear,
                            iconColor.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
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
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: 4)
    
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
                            // Grand Total Card
                            EnhancedMetricCard(
                                title: "Revenue Overview",
                                icon: "dollarsign.circle.fill",
                                iconColor: .green,
                                metrics: [
                                    MetricData(
                                        icon: "banknote.fill",
                                        title: "Total Earnings",
                                        value: metrics.formattedEstimatedEarnings,
                                        subtitle: "Revenue Generated",
                                        color: .green
                                    )
                                ]
                            )
                            .opacity(cardAppearances[0] ? 1 : 0)
                            .offset(y: cardAppearances[0] ? 0 : 30)
                            
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
                            .opacity(cardAppearances[1] ? 1 : 0)
                            .offset(y: cardAppearances[1] ? 0 : 30)
                            
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
                            .opacity(cardAppearances[2] ? 1 : 0)
                            .offset(y: cardAppearances[2] ? 0 : 30)
                            
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
                            .opacity(cardAppearances[3] ? 1 : 0)
                            .offset(y: cardAppearances[3] ? 0 : 30)
                        }
                        .padding(.horizontal, 20)
                        
                        // Footer disclaimer
                        Text("AdRadar is not affiliated with Google or Google AdSense.")
                            .soraFootnote()
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
                    .soraBody()
                    .foregroundColor(.accentColor)
                }
            }
        }
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
                    .frame(width: 60, height: 60)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 15, x: 0, y: 8)
                
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text(title.capitalized)
                    .soraTitle2()
                    .foregroundColor(.primary)
                
                Text("Comprehensive performance overview")
                    .soraSubheadline()
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
                            .soraHeadline()
                            .foregroundColor(.primary)
                        
                        Text("Performance insights")
                            .soraCaption()
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
                        .soraSubheadline()
                        .foregroundColor(.primary)
                    
                    Text(metric.subtitle)
                        .soraCaption()
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text(metric.value)
                .soraTitle()
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
                        .soraCaption()
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(metric.subtitle)
                        .soraCaption2()
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Text(metric.value)
                .soraCallout()
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Summary Floating Elements
struct SummaryFloatingElementsView: View {
    @Binding var animate: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Floating circles positioned for summary content
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 40, height: 40)
                    .position(x: geometry.size.width * 0.15, y: geometry.size.height * 0.2)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.0).delay(0.3), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 60, height: 60)
                    .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.15)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.5).delay(0.8), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.06))
                    .frame(width: 35, height: 35)
                    .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.6)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.2).delay(1.2), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.04))
                    .frame(width: 50, height: 50)
                    .position(x: geometry.size.width * 0.9, y: geometry.size.height * 0.7)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.8).delay(1.6), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.07))
                    .frame(width: 25, height: 25)
                    .position(x: geometry.size.width * 0.3, y: geometry.size.height * 0.85)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.1).delay(2.0), value: animate)
            }
        }
    }
}

#Preview {
    SummaryView(showSlideOverMenu: .constant(false), selectedTab: .constant(0))
}
