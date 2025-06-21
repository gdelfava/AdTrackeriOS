import SwiftUI
import Charts

struct StreakView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: StreakViewModel
    @State private var selectedDay: StreakDayData?
    @State private var calendarAppeared = false
    @State private var overviewAppeared = false
    @State private var detailsAppeared = false
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
            ScrollView {
                VStack(spacing: 24) {
                    if let error = viewModel.error {
                        ErrorBannerView(message: error, symbol: errorSymbol(for: error))
                            .padding(.horizontal)
                    }
                    
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading...")
                            .padding()
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
                        
                        // 7-Day Overview Cards
                        OverviewCardsView(streakData: viewModel.streakData, viewModel: viewModel)
                            .opacity(overviewAppeared ? 1 : 0)
                            .offset(y: overviewAppeared ? 0 : 20)
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
                    }
                }
                .padding(.vertical)
            }
            .refreshable {
                if let token = authViewModel.accessToken {
                    viewModel.accessToken = token
                    viewModel.authViewModel = authViewModel
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
            if let token = authViewModel.accessToken, !viewModel.hasLoaded {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                Task { await viewModel.fetchStreakData() }
            }
            
            // Staggered animations
            withAnimation(.easeOut(duration: 0.5)) {
                calendarAppeared = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                overviewAppeared = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                detailsAppeared = true
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
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.horizontal, 4)
            
            Text("Select Date")
                .font(.subheadline)
                .fontWeight(.medium)
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
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text(dayText)
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .white : .primary)
                
                // Earnings indicator
                Text(viewModel.formatCurrency(day.earnings))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                
                // Data indicator dot
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.8) : Color.accentColor)
                    .frame(width: 4, height: 4)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color(.separator), lineWidth: 0.5)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
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
    @State private var showAllMetrics = true // Always show all metrics
    
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
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.accentColor)
                            .frame(width: 40, height: 40)
                            .background(Color.accentColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayOfWeek)
                                .font(.title2)
                                .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                    // Close button (only if showCloseButton is true)
                    if showCloseButton {
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                // This will be handled by the parent view
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Main earnings display
                HStack {
            VStack(alignment: .leading, spacing: 4) {
                        Text("Total Earnings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .fontWeight(.medium)
                
                Text(viewModel.formatCurrency(day.earnings))
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
                    
                    Spacer()
                    
                    // Delta indicator
                    if let delta = day.delta {
                        VStack(alignment: .trailing, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: day.deltaPositive == true ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                    .foregroundColor(day.deltaPositive == true ? .green : .red)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text(viewModel.formatCurrency(abs(delta)))
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(day.deltaPositive == true ? .green : .red)
                            }
                            
                            Text("vs previous day")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background((day.deltaPositive == true ? Color.green : Color.red).opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
            .padding(20)
            
            // Primary Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DayMetricCard(
                icon: "cursorarrow.click.2",
                title: "Clicks",
                value: "\(day.clicks)",
                color: .blue
            )
            
                DayMetricCard(
                icon: "eye.fill",
                title: "Impressions",
                value: "\(day.impressions)",
                color: .orange
            )
            
                DayMetricCard(
                icon: "percent",
                title: "CTR",
                value: viewModel.formatPercentage(day.impressionCTR),
                color: .purple
            )
                
                DayMetricCard(
                    icon: "dollarsign.circle.fill",
                    title: "Cost/Click",
                    value: viewModel.formatCurrency(day.costPerClick),
                    color: .pink
                )
        }
        .padding(.horizontal, 20)
            .padding(.bottom, 16)
    
            // Additional Metrics (always visible now)
        VStack(spacing: 0) {
            Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                    DayMetricCard(
                    icon: "doc.text.fill",
                    title: "Requests",
                    value: "\(day.requests)",
                    color: .indigo
                )
                
                    DayMetricCard(
                    icon: "newspaper.fill",
                    title: "Page Views",
                    value: "\(day.pageViews)",
                    color: .teal
                )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
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
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
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
    @State private var isExpanded = false
    
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
        VStack(alignment: .leading, spacing: 0) {
            // Collapsible Header
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("7-Day Overview")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if !isExpanded {
                            Text("Total: \(viewModel.formatCurrency(totalEarnings))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        // Quick summary when collapsed
                        if !isExpanded {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(totalClicks) clicks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(totalImpressions) views")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Expand/Collapse icon
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable Content
            if isExpanded {
                VStack(spacing: 16) {
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
                            title: "Total Impressions",
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
                .padding(.top, 12)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
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
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(title)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Extensions

extension Date {
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
}

#Preview {
    StreakView(showSlideOverMenu: .constant(false), selectedTab: .constant(0))
        .environmentObject(AuthViewModel())
} 
