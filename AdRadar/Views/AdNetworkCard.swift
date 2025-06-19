import SwiftUI

struct AdNetworkCard: View {
    let adNetwork: AdNetworkData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with ad network type and earnings
            HStack {
                Text(adNetwork.formattedEarnings)
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(adNetwork.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
            
            // Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AdNetworkMetricView(title: "Requests", value: adNetwork.requests)
                AdNetworkMetricView(title: "Page Views", value: adNetwork.pageViews)
                AdNetworkMetricView(title: "Impressions", value: adNetwork.impressions)
                AdNetworkMetricView(title: "Clicks", value: adNetwork.clicks)
                AdNetworkMetricView(title: "CTR", value: adNetwork.formattedCTR)
                AdNetworkMetricView(title: "RPM", value: adNetwork.formattedRPM)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct AdNetworkMetricView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    AdNetworkCard(adNetwork: AdNetworkData(
        adNetworkType: "content",
        earnings: "123.45",
        requests: "1000",
        pageViews: "5000",
        impressions: "800",
        clicks: "25",
        ctr: "0.03125",
        rpm: "15.43"
    ))
    .padding()
} 
