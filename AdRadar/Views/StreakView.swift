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
                        // Bar Chart
                        VStack(alignment: .leading, spacing: 8) {
                            Text("7 Day Earnings Trend")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .opacity(chartTitleAppeared ? 1 : 0)
                                .offset(y: chartTitleAppeared ? 0 : 20)
                            
                            Chart {
                                ForEach(Array(viewModel.streakData.sorted(by: { $0.date < $1.date }).enumerated()), id: \.element.id) { index, day in
                                    BarMark(
                                        x: .value("Date", day.date, unit: .day),
                                        y: .value("Earnings", barAnimations.indices.contains(index) && barAnimations[index] ? day.earnings : 0)
                                    )
                                    .foregroundStyle(Color.accentColor.gradient)
                                    .annotation(position: .top) {
                                        if selectedDay?.id == day.id {
                                            Text(viewModel.formatCurrency(day.earnings))
                                                .font(.caption)
                                                .padding(4)
                                                .background(Color(.secondarySystemBackground))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            .chartOverlay { proxy in
                                GeometryReader { geometry in
                                    ChartOverlayView(proxy: proxy, geometry: geometry, viewModel: viewModel, selectedDay: $selectedDay)
                                }
                            }
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
        .onChange(of: viewModel.streakData.count) { oldCount, newCount in
            // Update animation arrays when data changes
            barAnimations = Array(repeating: false, count: newCount)
            cardAppearances = Array(repeating: false, count: newCount)
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

struct StreakDayCard: View {
    let day: StreakDayData
    let viewModel: StreakViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(day.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let delta = day.delta {
                    HStack(spacing: 4) {
                        Image(systemName: day.deltaPositive == true ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .foregroundColor(day.deltaPositive == true ? .green : .red)
                        Text(viewModel.formatCurrency(delta))
                            .font(.subheadline)
                            .foregroundColor(day.deltaPositive == true ? .green : .red)
                    }
                }
            }
            
            Text(viewModel.formatCurrency(day.earnings))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricView(title: "Clicks", value: "\(day.clicks)")
                MetricView(title: "Impressions", value: "\(day.impressions)")
                MetricView(title: "CTR", value: viewModel.formatPercentage(day.impressionCTR))
                MetricView(title: "Requests", value: "\(day.requests)")
                MetricView(title: "Page Views", value: "\(day.pageViews)")
                MetricView(title: "CPC", value: viewModel.formatCurrency(day.costPerClick))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct MetricView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ChartOverlayView: View {
    let proxy: ChartProxy
    let geometry: GeometryProxy
    let viewModel: StreakViewModel
    @Binding var selectedDay: StreakDayData?
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard let plotFrame = proxy.plotFrame else { return }
                        let x = value.location.x - geometry[plotFrame].origin.x
                        guard let date = proxy.value(atX: x) as Date? else { return }
                        
                        // Find the closest day
                        selectedDay = viewModel.streakData.min(by: {
                            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                        })
                    }
                    .onEnded { _ in
                        selectedDay = nil
                    }
            )
    }
}

#Preview {
    StreakView(showSlideOverMenu: .constant(false), selectedTab: .constant(0))
        .environmentObject(AuthViewModel())
} 
