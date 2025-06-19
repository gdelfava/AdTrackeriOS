import SwiftUI

struct PlatformCard: View {
    let platform: PlatformData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with platform name and earnings
            HStack {
                
                Text(platform.formattedEarnings)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(platform.platform)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible(), alignment: .leading),
                GridItem(.flexible(), alignment: .leading)
            ], spacing: 16) {
                PlatformMetricRow(title: "Page Views", value: platform.pageViews)
                PlatformMetricRow(title: "Page RPM", value: platform.formattedPageRPM)
                PlatformMetricRow(title: "Impressions", value: platform.impressions)
                PlatformMetricRow(title: "Impression RPM", value: platform.formattedImpressionsRPM)
                PlatformMetricRow(title: "Active View", value: platform.formattedActiveViewViewable)
                PlatformMetricRow(title: "Clicks", value: platform.clicks)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PlatformMetricRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    PlatformCard(platform: PlatformData(
        platform: "Desktop",
        earnings: "123.45",
        pageViews: "5000",
        pageRPM: "24.69",
        impressions: "800",
        impressionsRPM: "154.31",
        activeViewViewable: "0.95",
        clicks: "25"
    ))
    .padding()
} 
