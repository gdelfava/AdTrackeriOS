import SwiftUI

struct SelectedDayMetricsView: View {
    let day: StreakDayData
    let viewModel: StreakViewModel
    let showCloseButton: Bool
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: day.date)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate)
                        .soraTitle3()
                        .foregroundColor(.primary)
                    Text("Daily Performance")
                        .soraSubheadline()
                        .foregroundColor(.secondary)
                }
                Spacer()
                if showCloseButton {
                    Button(action: {
                        // Handle close action
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.title2)
                    }
                }
            }
            
            // Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Revenue",
                    value: viewModel.formatCurrency(day.earnings),
                    icon: "dollarsign.circle.fill",
                    color: .green
                )
                MetricCard(
                    title: "Impressions",
                    value: viewModel.formatNumber(day.impressions),
                    icon: "eye.fill",
                    color: .blue
                )
                MetricCard(
                    title: "Clicks",
                    value: viewModel.formatNumber(day.clicks),
                    icon: "hand.tap.fill",
                    color: .orange
                )
                MetricCard(
                    title: "CTR",
                    value: viewModel.formatPercentage(day.impressionCTR),
                    icon: "percent",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }
}

// MARK: - Metric Card
private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .soraSubheadline()
                    .foregroundColor(.secondary)
            }
            Text(value)
                .soraTitle3()
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
} 