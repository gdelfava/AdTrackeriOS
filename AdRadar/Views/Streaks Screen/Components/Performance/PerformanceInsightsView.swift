import SwiftUI
import Charts

struct PerformanceInsightsView: View {
    let streakData: [StreakDayData]
    let viewModel: StreakViewModel
    
    private var weeklyData: [StreakDayData] {
        Array(streakData.prefix(7))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Performance Insights")
                .soraTitle3()
                .foregroundColor(.primary)
            
            // Revenue Chart
            InsightCard(
                title: "Revenue Trend",
                data: weeklyData,
                valueKey: \.earnings,
                color: .green,
                formatter: viewModel.formatCurrency
            )
            
            // Impressions Chart
            InsightCard(
                title: "Impressions Trend",
                data: weeklyData,
                valueKey: { Double($0.impressions) },
                color: .blue,
                formatter: { viewModel.formatNumber(Int($0)) }
            )
            
            // CTR Chart
            InsightCard(
                title: "CTR Trend",
                data: weeklyData,
                valueKey: \.impressionCTR,
                color: .purple,
                formatter: viewModel.formatPercentage
            )
        }
    }
}

// MARK: - Insight Card
private struct InsightCard: View {
    let title: String
    let data: [StreakDayData]
    let valueKey: (StreakDayData) -> Double
    let color: Color
    let formatter: (Double) -> String
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .soraSubheadline()
                .foregroundColor(.secondary)
            
            Chart(data, id: \.date) { day in
                LineMark(
                    x: .value("Date", day.date),
                    y: .value("Value", valueKey(day))
                )
                .foregroundStyle(color)
                .symbol(Circle().strokeBorder(lineWidth: 2))
                
                AreaMark(
                    x: .value("Date", day.date),
                    y: .value("Value", valueKey(day))
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [color.opacity(0.2), color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel(dateFormatter.string(from: date))
                    }
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    if let doubleValue = value.as(Double.self) {
                        AxisValueLabel(formatter(doubleValue))
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
} 