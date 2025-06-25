import SwiftUI
import Charts

struct OverviewCardsView: View {
    let streakData: [StreakDayData]
    let viewModel: StreakViewModel
    
    private var weeklyRevenue: Double {
        streakData.prefix(7).reduce(into: 0.0) { sum, day in
            sum += day.earnings
        }
    }
    
    private var weeklyImpressions: Int {
        streakData.prefix(7).reduce(into: 0) { sum, day in
            sum += day.impressions
        }
    }
    
    private var weeklyClicks: Int {
        streakData.prefix(7).reduce(into: 0) { sum, day in
            sum += day.clicks
        }
    }
    
    private var weeklyAverageCTR: Double {
        let clicks = Double(weeklyClicks)
        let impressions = Double(weeklyImpressions)
        return impressions > 0 ? (clicks / impressions) * 100 : 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("7-Day Overview")
                .soraTitle3()
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                OverviewCard(
                    title: "Total Revenue",
                    value: viewModel.formatCurrency(weeklyRevenue),
                    icon: "dollarsign.circle.fill",
                    color: .green,
                    data: streakData.prefix(7).map { $0.earnings }
                )
                
                OverviewCard(
                    title: "Total Impressions",
                    value: viewModel.formatNumber(weeklyImpressions),
                    icon: "eye.fill",
                    color: .blue,
                    data: streakData.prefix(7).map { Double($0.impressions) }
                )
                
                OverviewCard(
                    title: "Total Clicks",
                    value: viewModel.formatNumber(weeklyClicks),
                    icon: "hand.tap.fill",
                    color: .orange,
                    data: streakData.prefix(7).map { Double($0.clicks) }
                )
                
                OverviewCard(
                    title: "Average CTR",
                    value: viewModel.formatPercentage(weeklyAverageCTR),
                    icon: "percent",
                    color: .purple,
                    data: streakData.prefix(7).map { $0.impressionCTR }
                )
            }
        }
    }
}

// MARK: - Overview Card
private struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let data: [Double]
    
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
            
            // Mini Sparkline Chart
            Chart(Array(data.enumerated()), id: \.0) { index, value in
                LineMark(
                    x: .value("Day", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(color.opacity(0.8))
                
                AreaMark(
                    x: .value("Day", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [color.opacity(0.2), color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 40)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
} 