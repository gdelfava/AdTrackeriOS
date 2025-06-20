import SwiftUI
import Charts

struct StreakView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: StreakViewModel
    @State private var selectedDay: StreakDayData?
    @State private var chartTitleAppeared = false
    @State private var barAnimations: [Bool] = []
    @State private var cardAppearances: [Bool] = []
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: StreakViewModel(accessToken: nil))
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
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
                        // Enhanced Bar Chart
                        VStack(alignment: .leading, spacing: 20) {
                            // Modern Chart Header
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("7 Day Earnings Trend")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                        
                                        Text("Track your weekly adsense performance")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Chart summary badge
                                    if !viewModel.streakData.isEmpty {
                                        let totalEarnings = viewModel.streakData.reduce(0) { $0 + $1.earnings }
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text("7 Day Total")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                                .textCase(.uppercase)
                                                .fontWeight(.medium)
                                            
                                            Text(viewModel.formatCurrency(totalEarnings))
                                                .font(.system(.headline, design: .rounded))
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .opacity(chartTitleAppeared ? 1 : 0)
                            .offset(y: chartTitleAppeared ? 0 : 30)
                            
                            // Enhanced Chart Container
                            VStack(spacing: 0) {
                                chartView
                                .frame(height: 220)
                                .padding(.horizontal, 24)
                                .padding(.top, 20)
                                .padding(.bottom, 16)
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: .day)) { value in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                                        AxisValueLabel {
                                            if let date = value.as(Date.self) {
                                                Text(date, format: .dateTime.weekday(.abbreviated))
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0))
                                        AxisValueLabel {
                                            if let earnings = value.as(Double.self) {
                                                Text(viewModel.formatCurrency(earnings))
                                                    .font(.caption2)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .chartOverlay { proxy in
                                    GeometryReader { geometry in
                                        EnhancedChartOverlayView(
                                            proxy: proxy,
                                            geometry: geometry,
                                            viewModel: viewModel,
                                            selectedDay: $selectedDay
                                        )
                                    }
                                }
                                
                                // Selected day info panel
                                if let selectedDay = selectedDay {
                                    VStack(spacing: 0) {
                                        Rectangle()
                                            .fill(Color(.systemGray6))
                                            .frame(height: 1)
                                        
                                        HStack(spacing: 16) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(selectedDay.date, format: .dateTime.weekday(.wide).day().month(.abbreviated))
                                                    .font(.headline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.primary)
                                                
                                                Text("Daily Earnings")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .textCase(.uppercase)
                                                    .fontWeight(.medium)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(viewModel.formatCurrency(selectedDay.earnings))
                                                .font(.system(.title2, design: .rounded))
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 16)
                                        .background(.ultraThinMaterial)
                                    }
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .move(edge: .bottom).combined(with: .opacity)
                                    ))
                                }
                            }
                            .background(chartContainerBackground)
                            .overlay(chartContainerBorder)
                            .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
                            .shadow(color: Color.accentColor.opacity(0.1), radius: 20, x: 0, y: 10)
                            .padding(.horizontal, 20)
                            .onAppear {
                                // Animate chart title first
                                withAnimation(.easeOut(duration: 0.3)) {
                                    chartTitleAppeared = true
                                }
                                
                                // Animate chart bars from latest to earliest date (right to left)
                                let sortedData = viewModel.streakData.sorted(by: { $0.date > $1.date })
                                for i in 0..<sortedData.count {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 + Double(i) * 0.08) {
                                        withAnimation(.easeOut(duration: 0.4)) {
                                            // Find the index in the original array for this sorted item
                                            if let originalIndex = viewModel.streakData.firstIndex(where: { $0.id == sortedData[i].id }) {
                                                barAnimations[originalIndex] = true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Daily Cards
                        VStack(spacing: 16) {
                            ForEach(Array(viewModel.streakData.enumerated()), id: \.element.id) { index, day in
                                StreakDayCard(day: day, viewModel: viewModel)
                                    .opacity(cardAppearances.indices.contains(index) && cardAppearances[index] ? 1 : 0)
                                    .offset(y: cardAppearances.indices.contains(index) && cardAppearances[index] ? 0 : 20)
                            }
                        }
                        .padding(.horizontal)
                        .onAppear {
                            // Animate cards with staggered delay after bars finish
                            let totalBarAnimationTime = 0.2 + Double(barAnimations.count) * 0.08 + 0.4
                            for i in 0..<cardAppearances.count {
                                withAnimation(.easeOut(duration: 0.3).delay(totalBarAnimationTime + Double(i) * 0.06)) {
                                    cardAppearances[i] = true
                                }
                            }
                        }
                        .onDisappear {
                            // Reset animation states when view disappears
                            chartTitleAppeared = false
                            barAnimations = Array(repeating: false, count: viewModel.streakData.count)
                            cardAppearances = Array(repeating: false, count: viewModel.streakData.count)
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
            
            // Initialize animation arrays based on data count
            barAnimations = Array(repeating: false, count: viewModel.streakData.count)
            cardAppearances = Array(repeating: false, count: viewModel.streakData.count)
        }
        .onChange(of: viewModel.streakData.count) { _, newCount in
            // Update animation arrays when data changes
            barAnimations = Array(repeating: false, count: newCount)
            cardAppearances = Array(repeating: false, count: newCount)
        }
    }
    
    // MARK: - Chart Components
    
    private var chartView: some View {
        Chart {
            ForEach(Array(viewModel.streakData.sorted(by: { $0.date < $1.date }).enumerated()), id: \.element.id) { index, day in
                BarMark(
                    x: .value("Date", day.date, unit: .day),
                    y: .value("Earnings", barAnimations.indices.contains(index) && barAnimations[index] ? day.earnings : 0)
                )
                .foregroundStyle(barGradient(for: day))
                .cornerRadius(6, style: .continuous)
                .opacity(selectedDay == nil || selectedDay?.id == day.id ? 1.0 : 0.4)
            }
            
            // Add subtle grid lines
            if let maxEarnings = viewModel.streakData.map(\.earnings).max() {
                ForEach([0.25, 0.5, 0.75], id: \.self) { fraction in
                    RuleMark(y: .value("Grid", maxEarnings * fraction))
                        .foregroundStyle(Color(.systemGray5))
                        .lineStyle(StrokeStyle(lineWidth: 0.5, dash: [2, 4]))
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedDay?.id)
    }
    
    private func barGradient(for day: StreakDayData) -> LinearGradient {
        let isSelected = selectedDay?.id == day.id
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: isSelected ? Color.accentColor : Color.accentColor.opacity(0.9), location: 0),
                .init(color: isSelected ? Color.accentColor.opacity(0.8) : Color.accentColor.opacity(0.6), location: 0.7),
                .init(color: isSelected ? Color.accentColor.opacity(0.6) : Color.accentColor.opacity(0.3), location: 1)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var chartContainerBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
            
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(backgroundGradient)
        }
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(.systemBackground).opacity(0.8), location: 0),
                .init(color: Color(.secondarySystemBackground).opacity(0.4), location: 1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var chartContainerBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(borderGradient, lineWidth: 0.5)
    }
    
    private var borderGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemGray4).opacity(0.3),
                Color(.systemGray5).opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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

struct StreakDayCard: View {
    let day: StreakDayData
    let viewModel: StreakViewModel
    @State private var isPressed = false
    @State private var showDetailedMetrics = false
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: day.date)
    }
    
    private var formattedDate: String {
        day.date.formatted(date: .abbreviated, time: .omitted)
    }
    
    private var dayIcon: String {
        switch dayOfWeek.lowercased() {
        case "monday":
            return "calendar.circle.fill"
        case "tuesday":
            return "calendar.badge.plus"
        case "wednesday":
            return "calendar"
        case "thursday":
            return "calendar.badge.clock"
        case "friday":
            return "calendar.badge.checkmark"
        case "saturday":
            return "sun.max.fill"
        case "sunday":
            return "moon.stars.fill"
        default:
            return "calendar"
        }
    }
    
    private var dayColor: Color {
        switch dayOfWeek.lowercased() {
        case "monday":
            return .blue
        case "tuesday":
            return .green
        case "wednesday":
            return .orange
        case "thursday":
            return .purple
        case "friday":
            return .pink
        case "saturday":
            return .yellow
        case "sunday":
            return .indigo
        default:
            return .accentColor
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            headerSection
            
            // Divider
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // Main Metrics Section
            mainMetricsSection
            
            // Detailed Metrics Section (expandable)
            if showDetailedMetrics {
                detailedMetricsSection
            }
            
            // Expand/Collapse Button
            expandButton
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: showDetailedMetrics)
        .onTapGesture {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetailedMetrics.toggle()
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Day icon and date
                HStack(spacing: 12) {
                    Image(systemName: dayIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(dayColor)
                        .frame(width: 32, height: 32)
                        .background(dayColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dayOfWeek)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Delta indicator (if available)
                if let delta = day.delta {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: day.deltaPositive == true ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(day.deltaPositive == true ? .green : .red)
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(viewModel.formatCurrency(delta))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(day.deltaPositive == true ? .green : .red)
                        }
                        
                        Text("vs previous")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background((day.deltaPositive == true ? Color.green : Color.red).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            
            // Main earnings display
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Earnings")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .fontWeight(.medium)
                
                Text(viewModel.formatCurrency(day.earnings))
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var mainMetricsSection: some View {
        HStack(spacing: 0) {
            StreakMetricPill(
                icon: "cursorarrow.click.2",
                title: "Clicks",
                value: "\(day.clicks)",
                color: .blue
            )
            
            Divider()
                .frame(height: 40)
            
            StreakMetricPill(
                icon: "eye.fill",
                title: "Impressions",
                value: "\(day.impressions)",
                color: .orange
            )
            
            Divider()
                .frame(height: 40)
            
            StreakMetricPill(
                icon: "percent",
                title: "CTR",
                value: viewModel.formatPercentage(day.impressionCTR),
                color: .purple
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var detailedMetricsSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StreakDetailedMetricRow(
                    icon: "doc.text.fill",
                    title: "Requests",
                    value: "\(day.requests)",
                    color: .indigo
                )
                
                StreakDetailedMetricRow(
                    icon: "newspaper.fill",
                    title: "Page Views",
                    value: "\(day.pageViews)",
                    color: .teal
                )
                
                StreakDetailedMetricRow(
                    icon: "dollarsign.circle.fill",
                    title: "Cost Per Click",
                    value: viewModel.formatCurrency(day.costPerClick),
                    color: .pink
                )
                
                StreakDetailedMetricRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Revenue",
                    value: viewModel.formatCurrency(day.earnings),
                    color: .green
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
    }
    
    private var expandButton: some View {
        HStack {
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetailedMetrics.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Text(showDetailedMetrics ? "Less Details" : "More Details")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Image(systemName: showDetailedMetrics ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding(.bottom, 16)
    }
}

struct StreakMetricPill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                    .textCase(.uppercase)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct StreakDetailedMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct EnhancedChartOverlayView: View {
    let proxy: ChartProxy
    let geometry: GeometryProxy
    let viewModel: StreakViewModel
    @Binding var selectedDay: StreakDayData?
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { location in
                guard let plotFrame = proxy.plotFrame else { return }
                let x = location.x - geometry[plotFrame].origin.x
                guard let date = proxy.value(atX: x) as Date? else { return }
                
                // Find the closest day
                let closestDay = viewModel.streakData.min(by: {
                    abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                })
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedDay = selectedDay?.id == closestDay?.id ? nil : closestDay
                }
            }
            .onLongPressGesture(minimumDuration: 0.0, maximumDistance: 50) {
                // This handles the immediate press down for better responsiveness
            } onPressingChanged: { pressing in
                if !pressing {
                    // This ensures the tap gesture fires reliably
                }
            }
    }
}

#Preview {
    StreakView(showSlideOverMenu: .constant(false), selectedTab: .constant(0))
        .environmentObject(AuthViewModel())
} 
