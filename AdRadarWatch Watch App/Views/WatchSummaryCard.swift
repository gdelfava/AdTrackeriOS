import SwiftUI

struct WatchSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let delta: String?
    let deltaPositive: Bool?
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header with icon and title
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.custom("Sora-Regular", size: 10))
                
                Text(title)
                    .font(.custom("Sora-Regular", size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            // Main value
            Text(value)
                .font(.custom("Sora-SemiBold", size: 20))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Delta information
            if let delta = delta {
                HStack(spacing: 2) {
                    Image(systemName: deltaPositive == true ? "arrow.up" : "arrow.down")
                        .font(.custom("Sora-Light", size: 9))
                        .foregroundColor(deltaPositive == true ? .green : .red)
                    
                    Text(delta)
                        .font(.custom("Sora-Light", size: 9))
                        .foregroundColor(deltaPositive == true ? .green : .red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            
            // Subtitle
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.custom("Sora-Light", size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct WatchHeroCard: View {
    let title: String
    let value: String
    let subtitle: String
    let delta: String?
    let deltaPositive: Bool?
    
    var body: some View {
        VStack(spacing: 6) {
            // Title and subtitle
            VStack(spacing: 2) {
                Text(title)
                    .font(.custom("Sora-Medium", size: 14))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.custom("Sora-Regular", size: 10))
                    .foregroundColor(.secondary)
            }
            
            // Main value - large and prominent
            Text(value)
                .font(.custom("Sora-Bold", size: 24))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            // Delta with enhanced styling
            if let delta = delta {
                HStack(spacing: 3) {
                    Image(systemName: deltaPositive == true ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.custom("Sora-Regular", size: 12))
                        .foregroundColor(deltaPositive == true ? .green : .red)
                    
                    Text(delta)
                        .font(.custom("Sora-Medium", size: 12))
                        .foregroundColor(deltaPositive == true ? .green : .red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill((deltaPositive == true ? Color.green : Color.red).opacity(0.1))
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1.5)
        )
    }
}

struct WatchMetricsCard: View {
    let clicks: String?
    let pageViews: String?
    let impressions: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.custom("Sora-Regular", size: 10))
                
                Text("Today's Stats")
                    .font(.custom("Sora-Regular", size: 10))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            VStack(spacing: 4) {
                if let clicks = clicks {
                    MetricRow(icon: "hand.tap.fill", label: "Clicks", value: clicks, color: .orange)
                }
                
                if let pageViews = pageViews {
                    MetricRow(icon: "doc.text.fill", label: "Page Views", value: pageViews, color: .blue)
                }
                
                if let impressions = impressions {
                    MetricRow(icon: "eye.fill", label: "Impressions", value: impressions, color: .green)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
        )
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.custom("Sora-Light", size: 9))
                .frame(width: 12)
            
            Text(label)
                .font(.custom("Sora-Light", size: 9))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.custom("Sora-Medium", size: 10))
                .foregroundColor(.primary)
        }
    }
}

#Preview("Summary Card") {
    WatchSummaryCard(
        title: "Yesterday",
        value: "R 12,30",
        subtitle: "vs same day last week",
        delta: "+R 0,50 (+4.2%)",
        deltaPositive: true,
        icon: "calendar.badge.clock",
        color: .orange
    )
    .padding()
}

#Preview("Hero Card") {
    WatchHeroCard(
        title: "Today So Far",
        value: "R 15,75",
        subtitle: "vs yesterday",
        delta: "+R 3,45 (+28.0%)",
        deltaPositive: true
    )
    .padding()
}

#Preview("Metrics Card") {
    WatchMetricsCard(
        clicks: "35",
        pageViews: "893",
        impressions: "2,140"
    )
    .padding()
} 