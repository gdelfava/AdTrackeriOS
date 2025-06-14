import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: SummaryViewModel
    
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
                            SummaryCardView(title: "Today so far", value: data.today, subtitle: "vs yesterday", delta: data.todayDelta, deltaPositive: data.todayDeltaPositive)
                                .onTapGesture {
                                    Task { await viewModel.fetchMetrics(forCard: .today) }
                                }
                            SummaryCardView(title: "Yesterday", value: data.yesterday, subtitle: "vs the same day last week", delta: data.yesterdayDelta, deltaPositive: data.yesterdayDeltaPositive)
                                .onTapGesture {
                                    Task { await viewModel.fetchMetrics(forCard: .yesterday) }
                                }
                            SummaryCardView(title: "Last 7 Days", value: data.last7Days, subtitle: "vs the previous 7 days", delta: data.last7DaysDelta, deltaPositive: data.last7DaysDeltaPositive)
                                .onTapGesture {
                                    Task { await viewModel.fetchMetrics(forCard: .last7Days) }
                                }
                            SummaryCardView(title: "This month", value: data.thisMonth, subtitle: "vs the same day last month", delta: data.thisMonthDelta, deltaPositive: data.thisMonthDeltaPositive)
                                .onTapGesture {
                                    Task { await viewModel.fetchMetrics(forCard: .thisMonth) }
                                }
                            SummaryCardView(title: "Last month", value: data.lastMonth, subtitle: "vs the month before last", delta: data.lastMonthDelta, deltaPositive: data.lastMonthDeltaPositive)
                                .onTapGesture {
                                    Task { await viewModel.fetchMetrics(forCard: .lastMonth) }
                                }
                            SummaryCardView(title: "Last three years", value: data.lifetime, subtitle: nil, delta: nil, deltaPositive: nil)
                                .onTapGesture {
                                    // Optionally implement for lifetime if needed
                                }
                        }
                        .padding(.horizontal)
                        Spacer(minLength: 32)
                        Text("AdTracker is not affiliated with Google or Google AdSense. All data is provided by Google and is subject to their terms of service.")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let subtitle = subtitle {
                    Spacer()
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Text(value)
                .font(.system(size: 34, weight: .semibold))
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
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct DayMetricsSheet: View {
    let metrics: AdSenseDayMetrics
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 0) {
            // Sticky header
            HStack {
                Spacer()
                Capsule()
                    .frame(width: 40, height: 5)
                    .foregroundColor(Color(.systemGray4))
                Spacer()
            }
            .padding(.top, 8)
            // Top bar with Done button and centered title
            HStack {
                Button(action: { dismiss() }) {
                    Text("Done")
                        .font(.body)
                        .foregroundColor(.accentColor)
                        .padding(.leading)
                }
                Spacer()
                Text("Today")
                    .font(.title2).bold()
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
                // Invisible button to balance the layout
                Text("Done")
                    .font(.largeTitle)
                    .opacity(0)
                    .padding(.trailing)
            }
            .padding(.vertical, 8)
            // Metrics list
            VStack(spacing: 0) {
                DayMetricRow(label: "Estimated Gross Revenue", value: metrics.formattedEstimatedEarnings, isCurrency: true)
                Divider()
                DayMetricRow(label: "Requests", value: metrics.requests)
                Divider()
                DayMetricRow(label: "Clicks", value: metrics.clicks)
                Divider()
                DayMetricRow(label: "Cost Per Click", value: metrics.formattedCostPerClick, isCurrency: true)
                Divider()
                DayMetricRow(label: "Impressions", value: metrics.impressions)
                Divider()
                DayMetricRow(label: "Impression CTR", value: metrics.formattedImpressionsCTR, isPercent: true)
                Divider()
                DayMetricRow(label: "Matched Requests", value: metrics.matchedRequests)
            }
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .padding(.horizontal)
            .padding(.top, 8)
            Spacer(minLength: 0)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .presentationDetents([.medium])
    }
}

struct DayMetricRow: View {
    let label: String
    let value: String
    var isCurrency: Bool = false
    var isPercent: Bool = false
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            Spacer()
            Text(formattedValue)
                .font(.body.weight(.semibold))
                .foregroundColor(.green)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color(.clear))
    }
    private var formattedValue: String {
        if isCurrency { return value }
        if isPercent, !value.hasSuffix("%") { return value + "%" }
        return value
    }
}

#Preview {
    SummaryView()
}
