import SwiftUI
import Charts

struct StreakView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: StreakViewModel
    @State private var selectedDay: StreakDayData?
    @State private var calendarAppeared = false
    @State private var overviewAppeared = false
    @State private var detailsAppeared = false
    @State private var animateFloatingElements = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: StreakViewModel(accessToken: nil))
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
    }
    
    // Auto-select current day if available, otherwise first day
    private var displayDay: StreakDayData? {
        selectedDay ?? currentDay ?? viewModel.streakData.first
    }
    
    // Find today's date in the data
    private var currentDay: StreakDayData? {
        let today = Date()
        return viewModel.streakData.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
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
                StreakFloatingElementsView(animate: $animateFloatingElements)
                
                ScrollView {
                VStack(spacing: 24) {
                    // Last Updated Header
                    if !viewModel.isLoading && !viewModel.streakData.isEmpty {
                        StreakHeaderView(lastUpdateTime: viewModel.lastUpdateTime)
                            .padding(.horizontal, 20)
                    }
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading...")
                            .soraBody()
                            .padding()
                        Spacer()
                    } else if viewModel.showEmptyState {
                        Spacer()
                        StreakEmptyStateView(message: viewModel.emptyStateMessage ?? "")
                        Spacer()
                    } else {
                                                // Compact Horizontal Date Picker
                        HorizontalDatePickerView(
                            selectedDay: $selectedDay,
                            streakData: viewModel.streakData
                        )
                        .opacity(calendarAppeared ? 1 : 0)
                        .offset(y: calendarAppeared ? 0 : 20)
                        .padding(.horizontal, 20)
                        
                        // Selected Day Detailed Metrics (Always Visible)
                        if let displayDay = displayDay {
                            SelectedDayMetricsView(
                                day: displayDay,
                                viewModel: viewModel,
                                showCloseButton: false
                            )
                            .opacity(detailsAppeared ? 1 : 0)
                            .offset(y: detailsAppeared ? 0 : 20)
                            .padding(.horizontal, 20)
                        }
                        
                        // 7-Day Overview Cards
                        OverviewCardsView(streakData: viewModel.streakData, viewModel: viewModel)
                            .opacity(overviewAppeared ? 1 : 0)
                            .offset(y: overviewAppeared ? 0 : 20)
                            .padding(.horizontal, 20)
                        
                        // Performance Insights Cards
                        PerformanceInsightsView(streakData: viewModel.streakData, viewModel: viewModel)
                            .opacity(overviewAppeared ? 1 : 0)
                            .offset(y: overviewAppeared ? 0 : 20)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical)
                }
            }
            .refreshable {
                if let token = authViewModel.accessToken {
                    viewModel.accessToken = token
                    viewModel.authViewModel = authViewModel
                    // Reset selected day to allow auto-selection of current day after refresh
                    selectedDay = nil
                    await viewModel.fetchStreakData()
                }
            }
            .navigationTitle("Streak")
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
        .onAppear {
            // Only fetch data on first load, not on every tab switch
            if let token = authViewModel.accessToken, !viewModel.hasLoaded {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                Task { await viewModel.fetchStreakData() }
            }
            
            // Staggered animations (these can run every time)
            withAnimation(.easeOut(duration: 0.5)) {
                calendarAppeared = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                overviewAppeared = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                detailsAppeared = true
            }
            
            // Animate floating elements
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateFloatingElements = true
            }
        }
        .onChange(of: viewModel.streakData) { _, newData in
            // Auto-select current day when data loads, fallback to first day
            if selectedDay == nil && !newData.isEmpty {
                let today = Date()
                selectedDay = newData.first { Calendar.current.isDate($0.date, inSameDayAs: today) } ?? newData.first
            }
        }
    }
    
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

// MARK: - Horizontal Date Picker

struct HorizontalDatePickerView: View {
    @Binding var selectedDay: StreakDayData?
    let streakData: [StreakDayData]
    
    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentMonthName)
                .soraTitle2()
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            Text("Select an Earnings Date")
                .soraSubheadline()
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(streakData.sorted(by: { $0.date < $1.date })) { day in
                            HorizontalDateItemView(
                                day: day,
                                isSelected: selectedDay?.id == day.id,
                                viewModel: StreakViewModel(accessToken: nil)
                            ) {
                                selectDay(day)
                            }
                            .id(day.id) // Add ID for scroll positioning
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)
                .onAppear {
                    // Scroll to the selected date (today) when view appears
                    if let selectedDay = selectedDay {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                proxy.scrollTo(selectedDay.id, anchor: .center)
                            }
                        }
                    }
                }
                .onChange(of: streakData) { _, newData in
                    // Scroll to current day when new data loads
                    let today = Date()
                    if let currentDay = newData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                proxy.scrollTo(currentDay.id, anchor: .center)
                            }
                        }
                    }
                }
                .onChange(of: selectedDay) { _, newSelectedDay in
                    // Scroll to newly selected date
                    if let newSelectedDay = newSelectedDay {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(newSelectedDay.id, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    private func selectDay(_ day: StreakDayData) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.easeOut(duration: 0.3)) {
            selectedDay = selectedDay?.id == day.id ? day : day
        }
    }
}

struct HorizontalDateItemView: View {
    let day: StreakDayData
    let isSelected: Bool
    let viewModel: StreakViewModel
    let onTap: () -> Void
    
    private var dayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: day.date)
    }
    
    private var weekdayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: day.date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(weekdayText)
                    .soraCaption()
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text(dayText)
                    .soraTitle2()
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Earnings value
                Text(viewModel.formatCurrency(day.earnings))
                    .soraCaption2()
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                
                // Data indicator dot
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.8) : Color.accentColor)
                    .frame(width: 4, height: 4)
            }
            .frame(width: 60, height: 80)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected ? 
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.accentColor.opacity(0.9), location: 0),
                                .init(color: Color.accentColor.opacity(0.8), location: 0.4),
                                .init(color: Color.accentColor.opacity(0.7), location: 1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.secondarySystemBackground)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color(.separator), lineWidth: 0.5)
            )
            .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.05), radius: isSelected ? 8 : 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Selected Day Metrics (Updated)

struct SelectedDayMetricsView: View {
    let day: StreakDayData
    let viewModel: StreakViewModel
    let showCloseButton: Bool
    @State private var isExpanded = false
    @State private var isPressed = false
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: day.date)
    }
    
    private var formattedDate: String {
        day.date.formatted(date: .complete, time: .omitted)
    }
    
    init(day: StreakDayData, viewModel: StreakViewModel, showCloseButton: Bool = true) {
        self.day = day
        self.viewModel = viewModel
        self.showCloseButton = showCloseButton
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    // Day info
                    HStack(spacing: 12) {
                        Image(systemName: "calendar.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.accentColor)
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dayOfWeek)
                                .soraHeadline()
                                .foregroundColor(.primary)
                            
                            Text("Daily Performance")
                                .soraCaption()
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Performance status badge
                    if let _ = day.delta, let deltaPositive = day.deltaPositive {
                        Text(deltaPositive ? "Up" : "Down")
                            .soraCaption()
                            .textCase(.uppercase)
                            .foregroundColor(deltaPositive ? .green : .red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background((deltaPositive ? Color.green : Color.red).opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                // Main earnings amount
                Text(viewModel.formatCurrency(day.earnings))
                    .soraLargeTitle()
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                // Main metrics pills
                HStack(spacing: 12) {
                    DayMetricPill(
                        icon: "cursorarrow.click.2",
                        title: "Clicks",
                        value: "\(day.clicks)",
                        color: .blue
                    )
                    
                    DayMetricPill(
                        icon: "eye.fill",
                        title: "Impressions",
                        value: "\(day.impressions)",
                        color: .orange
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
                        DayDetailedMetricRow(
                            icon: "percent",
                            title: "Click-Through Rate",
                            value: viewModel.formatPercentage(day.impressionCTR),
                            color: .purple
                        )
                        
                        DayDetailedMetricRow(
                            icon: "dollarsign.circle.fill",
                            title: "Cost Per Click",
                            value: viewModel.formatCurrency(day.costPerClick),
                            color: .yellow
                        )
                        
                        DayDetailedMetricRow(
                            icon: "doc.text.fill",
                            title: "Page Views",
                            value: "\(day.pageViews)",
                            color: .green
                        )
                        
                        DayDetailedMetricRow(
                            icon: "server.rack",
                            title: "Total Requests",
                            value: "\(day.requests)",
                            color: .red
                        )
                        
                        if let delta = day.delta, let deltaPositive = day.deltaPositive {
                            DayDetailedMetricRow(
                                icon: deltaPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill",
                                title: "Daily Change",
                                value: "\(deltaPositive ? "+" : "")\(viewModel.formatCurrency(delta))",
                                color: deltaPositive ? .green : .red
                            )
                        }
                        
                        DayDetailedMetricRow(
                            icon: "calendar.badge.plus",
                            title: "Date",
                            value: formattedDate,
                            color: .blue
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
                        .soraCaption()
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

struct DayMetricPill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color.opacity(0.8))
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .soraCaption()
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(getSubtitle())
                        .soraCaption2()
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
            }
            
            Text(value)
                .soraTitle3()
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: color.opacity(0.08), location: 0),
                    .init(color: color.opacity(0.04), location: 0.7),
                    .init(color: color.opacity(0.02), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
    
    private func getSubtitle() -> String {
        switch title.lowercased() {
        case "clicks":
            return "User Clicks"
        case "impressions":
            return "Ad Views"
        case "earnings":
            return "Revenue"
        default:
            return "Metric"
        }
    }
}

struct DayDetailedMetricRow: View {
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
                .soraCallout()
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .soraCallout()
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}

struct DayMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
            Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
                    .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .clipShape(Circle())
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .soraTitle2()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(title)
                    .soraCaption()
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: color.opacity(0.08), location: 0),
                    .init(color: color.opacity(0.04), location: 0.7),
                    .init(color: color.opacity(0.02), location: 1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(color.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Overview Cards

struct OverviewCardsView: View {
    let streakData: [StreakDayData]
    let viewModel: StreakViewModel
    
    private var totalEarnings: Double {
        streakData.reduce(0) { $0 + $1.earnings }
    }
    
    private var totalClicks: Int {
        streakData.reduce(0) { $0 + $1.clicks }
    }
    
    private var totalImpressions: Int {
        streakData.reduce(0) { $0 + $1.impressions }
    }
    
    private var averageCTR: Double {
        let totalCTR = streakData.reduce(0) { $0 + $1.impressionCTR }
        return streakData.isEmpty ? 0 : totalCTR / Double(streakData.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("7-Day Overview")
                .soraTitle2()
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                OverviewCard(
                    icon: "banknote.fill",
                    title: "Total Earnings",
                    value: viewModel.formatCurrency(totalEarnings),
                    color: .green
                )
                
                OverviewCard(
                    icon: "cursorarrow.click.2",
                    title: "Total Clicks",
                    value: "\(totalClicks)",
                    color: .blue
                )
                
                OverviewCard(
                    icon: "eye.fill",
                    title: "Total Impress.",
                    value: "\(totalImpressions)",
                    color: .orange
                )
                
                OverviewCard(
                    icon: "percent",
                    title: "Average CTR",
                    value: viewModel.formatPercentage(averageCTR),
                    color: .purple
                )
            }
        }
    }
}

struct OverviewCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
            Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
                    .frame(width: 36, height: 36)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .soraTitle()
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(title)
                    .soraCallout()
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}



// MARK: - Performance Insights

struct PerformanceInsightsView: View {
    let streakData: [StreakDayData]
    let viewModel: StreakViewModel
    
    private var bestDay: StreakDayData? {
        viewModel.bestPerformingDay
    }
    
    private var bestDayName: String {
        guard let bestDay = bestDay else { return "No Data" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: bestDay.date)
    }
    
    private var consistencyPercentage: String {
        let percentage = viewModel.performanceConsistency * 100
        return String(format: "%.0f%%", percentage)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Insights")
                .soraTitle2()
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                // Best Performing Day Row
                PerformanceInsightRow(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Best Performing Day",
                    value: bestDayName,
                    subtitle: viewModel.formatCurrency(bestDay?.earnings ?? 0),
                    isFirst: true
                )
                
                // Weekly Trend Row
                PerformanceInsightRow(
                    icon: viewModel.weeklyTrend.icon,
                    iconColor: viewModel.weeklyTrend.color,
                    title: "Weekly Trend",
                    value: viewModel.weeklyTrend.description,
                    subtitle: "Based on 7-day data"
                )
                
                // Performance Consistency Row
                PerformanceInsightRow(
                    icon: "speedometer",
                    iconColor: .cyan,
                    title: "Performance Consistency",
                    value: consistencyPercentage,
                    subtitle: "Revenue Stability score",
                    isLast: true
                )
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
    }
}

struct PerformanceInsightRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let subtitle: String
    let isFirst: Bool
    let isLast: Bool
    
    init(icon: String, iconColor: Color, title: String, value: String, subtitle: String, isFirst: Bool = false, isLast: Bool = false) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.isFirst = isFirst
        self.isLast = isLast
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 28, height: 28)
                    .background(iconColor.opacity(0.1))
                    .clipShape(Circle())
                
                // Title
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .soraCallout()
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(subtitle)
                        .soraCaption2()
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                // Value
                Text(value)
                    .soraCallout()
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            // Separator line (except for last item)
            if !isLast {
                Divider()
                    .padding(.leading, 56) // Align with text content
            }
        }
    }
}

struct PerformanceInsightCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let primaryValue: String
    let secondaryValue: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .soraCaption()
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(primaryValue)
                    .soraTitle3()
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(secondaryValue)
                    .soraCaption2()
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Weekly Earnings Chart

struct WeeklyEarningsChartView: View {
    let streakData: [StreakDayData]
    let viewModel: StreakViewModel
    
    private var sortedData: [StreakDayData] {
        streakData.sorted { $0.date < $1.date }
    }
    
    private var totalEarnings: Double {
        streakData.reduce(0) { $0 + $1.earnings }
    }
    
    private var averageEarnings: Double {
        streakData.isEmpty ? 0 : totalEarnings / Double(streakData.count)
    }
    
    private var maxEarnings: Double {
        streakData.map { $0.earnings }.max() ?? 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with title and stats
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Weekly Balance")
                        .soraTitle()
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Period indicator
                    Text("Last 7 Days")
                        .soraCaption()
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Capsule())
                }
                
                // Stats cards
                HStack(spacing: 16) {
                    StatCardView(
                        icon: "arrow.down.circle.fill",
                        iconColor: .green,
                        title: "Total Earnings",
                        value: viewModel.formatCurrency(totalEarnings),
                        change: nil,
                        changePositive: nil
                    )
                    
                    StatCardView(
                        icon: "chart.bar.fill",
                        iconColor: .blue,
                        title: "Daily Average",
                        value: viewModel.formatCurrency(averageEarnings),
                        change: nil,
                        changePositive: nil
                    )
                    
                    StatCardView(
                        icon: "star.fill",
                        iconColor: .orange,
                        title: "Best Day",
                        value: viewModel.formatCurrency(maxEarnings),
                        change: nil,
                        changePositive: nil
                    )
                }
            }
            
            // Chart
            if !sortedData.isEmpty {
                Chart(sortedData) { dayData in
                    // Earnings bars
                    BarMark(
                        x: .value("Day", dayData.date, unit: .day),
                        y: .value("Earnings", dayData.earnings)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.accentColor.opacity(0.8),
                                Color.accentColor.opacity(0.6)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                    
                    // Clicks as secondary bars (scaled down)
                    BarMark(
                        x: .value("Day", dayData.date, unit: .day),
                        y: .value("Clicks", Double(dayData.clicks) * (maxEarnings / Double(streakData.map { $0.clicks }.max() ?? 1)) * 0.3)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.6),
                                Color.cyan.opacity(0.4)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                    .soraCaption()
                                    .foregroundColor(.secondary)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(.separator))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let earnings = value.as(Double.self) {
                                Text(viewModel.formatCurrency(earnings))
                                    .soraCaption2()
                                    .foregroundColor(.secondary)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                            .foregroundStyle(Color(.separator))
                        AxisTick(stroke: StrokeStyle(lineWidth: 0))
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(Color(.systemBackground))
                        .border(Color.clear)
                }
                
                // Legend
                HStack(spacing: 20) {
                    LegendItem(color: Color.accentColor, label: "Earnings")
                    LegendItem(color: Color.cyan, label: "Clicks (scaled)")
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

struct StatCardView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let change: String?
    let changePositive: Bool?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(iconColor.opacity(0.1))
                    .clipShape(Circle())
                
                Spacer()
                
                if let change = change, let changePositive = changePositive {
                    Text(change)
                        .soraCaption2()
                        .foregroundColor(changePositive ? .green : .red)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((changePositive ? Color.green : Color.red).opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .soraCallout()
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .soraCaption2()
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .soraCaption2()
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Extensions

extension Date {
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
}

// MARK: - Streak Floating Elements
struct StreakFloatingElementsView: View {
    @Binding var animate: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Floating circles positioned for streak content
                Circle()
                    .fill(Color.accentColor.opacity(0.06))
                    .frame(width: 45, height: 45)
                    .position(x: geometry.size.width * 0.12, y: geometry.size.height * 0.25)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.2).delay(0.4), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.04))
                    .frame(width: 65, height: 65)
                    .position(x: geometry.size.width * 0.88, y: geometry.size.height * 0.18)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.7).delay(0.9), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 30, height: 30)
                    .position(x: geometry.size.width * 0.08, y: geometry.size.height * 0.55)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.1).delay(1.3), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.03))
                    .frame(width: 55, height: 55)
                    .position(x: geometry.size.width * 0.92, y: geometry.size.height * 0.72)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.5).delay(1.7), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.07))
                    .frame(width: 20, height: 20)
                    .position(x: geometry.size.width * 0.25, y: geometry.size.height * 0.88)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.0).delay(2.1), value: animate)
            }
        }
    }
}



// MARK: - Streak Header View

struct StreakHeaderView: View {
    let lastUpdateTime: Date?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Streak Empty State View

struct StreakEmptyStateView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(.orange)
            
            // Content
            VStack(spacing: 12) {
                Text("Account Attention Required")
                    .soraFont(.semibold, size: 20)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(message.isEmpty ? "Your AdSense account requires attention. Please check your account settings and resolve any pending issues to continue viewing your streak data." : message)
                    .soraBody()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            // Action suggestion
            VStack(spacing: 8) {
                Text("What you can do:")
                    .soraSubheadline()
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .soraBody()
                            .foregroundColor(.secondary)
                        Text("Log into your AdSense account and check for any alerts or notifications")
                            .soraBody()
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .soraBody()
                            .foregroundColor(.secondary)
                        Text("Verify your account information and payment details are up to date")
                            .soraBody()
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .soraBody()
                            .foregroundColor(.secondary)
                        Text("Resolve any policy violations or account issues")
                            .soraBody()
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .soraBody()
                            .foregroundColor(.secondary)
                        Text("Try refreshing once issues are resolved")
                            .soraBody()
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }
}

#Preview {
    StreakView(showSlideOverMenu: .constant(false), selectedTab: .constant(0))
        .environmentObject(AuthViewModel())
} 
