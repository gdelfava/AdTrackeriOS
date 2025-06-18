import SwiftUI
import Charts

struct StreakView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: StreakViewModel
    @State private var selectedDay: StreakDayData?
    
    init() {
        _viewModel = StateObject(wrappedValue: StreakViewModel(accessToken: nil))
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
                            Text("8 Day Earnings Trend")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            Chart {
                                ForEach(viewModel.streakData) { day in
                                    BarMark(
                                        x: .value("Date", day.date, unit: .day),
                                        y: .value("Earnings", day.earnings)
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
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
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
                        }
                        
                        // Daily Cards
                        VStack(spacing: 16) {
                            ForEach(viewModel.streakData) { day in
                                StreakDayCard(day: day, viewModel: viewModel)
                            }
                        }
                        .padding(.horizontal)
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

#Preview {
    StreakView()
        .environmentObject(AuthViewModel())
} 
