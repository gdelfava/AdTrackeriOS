import SwiftUI

struct AdSizeCard: View {
    let adSize: AdSizeData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Ad Size and Earnings
            HStack {
                
                Text(adSize.formattedEarnings)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(adSize.adSize)
                    .font(.caption)
                    .fontWeight(.regular)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            // Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                AdSizeMetricRow(title: "Requests", value: adSize.requests)
                AdSizeMetricRow(title: "Page Views", value: adSize.pageViews)
                AdSizeMetricRow(title: "Impressions", value: adSize.impressions)
                AdSizeMetricRow(title: "Clicks", value: adSize.clicks)
                AdSizeMetricRow(title: "CTR", value: adSize.formattedCTR)
                AdSizeMetricRow(title: "RPM", value: adSize.formattedRPM)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct AdSizeMetricRow: View {
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
