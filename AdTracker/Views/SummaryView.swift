import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: SummaryViewModel
    @State private var cardAppearances: [Bool] = Array(repeating: false, count: 6)
    
    init() {
        _viewModel = StateObject(wrappedValue: SummaryViewModel(accessToken: nil))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
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
                            SummaryCardView(title: "Today so far", value: data.today, subtitle: "vs yesterday", delta: data.todayDelta, deltaPositive: data.todayDeltaPositive, onTap: { Task { await viewModel.fetchMetrics(forCard: .today) } })
                                .opacity(cardAppearances[0] ? 1 : 0)
                                .offset(y: cardAppearances[0] ? 0 : 20)
                            SummaryCardView(title: "Yesterday", value: data.yesterday, subtitle: "vs the same day last week", delta: data.yesterdayDelta, deltaPositive: data.yesterdayDeltaPositive, onTap: { Task { await viewModel.fetchMetrics(forCard: .yesterday) } })
                                .opacity(cardAppearances[1] ? 1 : 0)
                                .offset(y: cardAppearances[1] ? 0 : 20)
                            SummaryCardView(title: "Last 7 Days", value: data.last7Days, subtitle: "vs the previous 7 days", delta: data.last7DaysDelta, deltaPositive: data.last7DaysDeltaPositive, onTap: { Task { await viewModel.fetchMetrics(forCard: .last7Days) } })
                                .opacity(cardAppearances[2] ? 1 : 0)
                                .offset(y: cardAppearances[2] ? 0 : 20)
                            SummaryCardView(title: "This month", value: data.thisMonth, subtitle: "vs the same day last month", delta: data.thisMonthDelta, deltaPositive: data.thisMonthDeltaPositive, onTap: { Task { await viewModel.fetchMetrics(forCard: .thisMonth) } })
                                .opacity(cardAppearances[3] ? 1 : 0)
                                .offset(y: cardAppearances[3] ? 0 : 20)
                            SummaryCardView(title: "Last month", value: data.lastMonth, subtitle: "vs the month before last", delta: data.lastMonthDelta, deltaPositive: data.lastMonthDeltaPositive, onTap: { Task { await viewModel.fetchMetrics(forCard: .lastMonth) } })
                                .opacity(cardAppearances[4] ? 1 : 0)
                                .offset(y: cardAppearances[4] ? 0 : 20)
                            SummaryCardView(title: "Last three years", value: data.lifetime, subtitle: nil, delta: nil, deltaPositive: nil)
                                .opacity(cardAppearances[5] ? 1 : 0)
                                .offset(y: cardAppearances[5] ? 0 : 20)
                                .onTapGesture {
                                    // Optionally implement for lifetime if needed
                                }
                        }
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
                        Text("AdsenseTracker is not affiliated with Google or Google AdSense. All data is provided by Google and is subject to their terms of service.")
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
                DayMetricsSheet(metrics: metrics)
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
        } else if error.localizedCaseInsensitiveContains("unauthorized") || error.localizedCaseInsensitiveContains("session") {
            return "person.crop.circle.badge.exclamationmark"
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let subtitle = subtitle {
                    Spacer()
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundColor(.primary)
            if let delta = delta, let positive = deltaPositive {
                HStack(spacing: 4) {
                    Image(systemName: positive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(positive ? .green : .red)
                        .font(.body)
                    Text(delta)
                        .font(.caption)
                        .foregroundColor(positive ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity, alignment: .center)
        .overlay(
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.trailing, 16),
            alignment: .trailing
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .opacity(isPressed ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.12), value: isPressed)
        .onTapGesture {
            isPressed = true
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isPressed = false
                onTap?()
            }
        }
    }
}

struct DayMetricsSheet: View {
    let metrics: AdSenseDayMetrics
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Sticky header with drag indicator
            VStack(spacing: 8) {
                Capsule()
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                
                // Header with date and close button
                HStack {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .font(.body.weight(.medium))
                            .foregroundColor(.accentColor)
                    }
                    Spacer()
                    Text("Today")
                        .font(.title3.weight(.semibold))
                    Spacer()
                    // Invisible button to balance the layout
                    Text("Done")
                        .font(.body)
                        .opacity(0)
                }
                .padding(.horizontal)
            }
            .background(Color(.systemGroupedBackground))
            
            // Metrics list
            ScrollView {
                VStack(spacing: 16) {
                    // Revenue section
                    MetricSection(title: "Revenue", icon: "dollarsign.circle.fill", color: .green) {
                        MetricRow(
                            icon: "chart.line.uptrend.xyaxis.circle.fill",
                            title: "Estimated Earnings",
                            value: metrics.formattedEstimatedEarnings,
                            color: .green
                        )
                    }
                    
                    // Performance section
                    MetricSection(title: "Performance", icon: "chart.bar.fill", color: .blue) {
                        MetricRow(
                            icon: "cursorarrow.click",
                            title: "Clicks",
                            value: metrics.clicks,
                            color: .blue
                        )
                        MetricRow(
                            icon: "eye.fill",
                            title: "Impressions",
                            value: metrics.impressions,
                            color: .blue
                        )
                        MetricRow(
                            icon: "percent",
                            title: "Impression CTR",
                            value: metrics.formattedImpressionsCTR,
                            color: .blue
                        )
                    }
                    
                    // Requests section
                    MetricSection(title: "Requests", icon: "arrow.triangle.2.circlepath", color: .orange) {
                        MetricRow(
                            icon: "doc.text.fill",
                            title: "Page Views",
                            value: metrics.requests,
                            color: .orange
                        )
                        MetricRow(
                            icon: "checkmark.circle.fill",
                            title: "Matched Requests",
                            value: metrics.matchedRequests,
                            color: .orange
                        )
                    }
                    
                    // Cost section
                    MetricSection(title: "Cost", icon: "creditcard.fill", color: .purple) {
                        MetricRow(
                            icon: "dollarsign.circle.fill",
                            title: "Cost Per Click",
                            value: metrics.formattedCostPerClick,
                            color: .purple
                        )
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
        .presentationDetents([.height(600)])
        .presentationDragIndicator(.visible)
    }
}

struct MetricSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct MetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }
}

#Preview {
    SummaryView()
}
