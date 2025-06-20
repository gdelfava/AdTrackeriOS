import SwiftUI

struct TargetingCard: View {
    let targeting: TargetingData
    @State private var isPressed = false
    @State private var showDetailedMetrics = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            headerSection
            
            // Divider
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // Main Metrics Section
            mainMetricsSection
            
            // Detailed Metrics Section (expandable)
            if showDetailedMetrics {
                detailedMetricsSection
            }
            
            // Expand/Collapse Button
            expandButton
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: showDetailedMetrics)
        .onTapGesture {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetailedMetrics.toggle()
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Targeting icon and name
                HStack(spacing: 12) {
                    Image(systemName: targeting.targetingIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(colorForTargeting)
                        .frame(width: 32, height: 32)
                        .background(colorForTargeting.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(targeting.displayTargetingType)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text("Targeting Performance")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Earnings badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(targeting.formattedEarnings)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Revenue")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var mainMetricsSection: some View {
        HStack(spacing: 0) {
            TargetingMetricPill(
                icon: "eye.fill",
                title: "Impressions",
                value: targeting.impressions,
                color: .blue
            )
            
            Divider()
                .frame(height: 40)
            
            TargetingMetricPill(
                icon: "cursorarrow.click.2",
                title: "Clicks",
                value: targeting.clicks,
                color: .orange
            )
            
            Divider()
                .frame(height: 40)
            
            TargetingMetricPill(
                icon: "percent",
                title: "CTR",
                value: targeting.formattedCTR,
                color: .purple
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var detailedMetricsSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                TargetingDetailedMetricRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "RPM",
                    value: targeting.formattedRPM,
                    color: .pink
                )
                
                TargetingDetailedMetricRow(
                    icon: "dollarsign.circle.fill",
                    title: "Total Revenue",
                    value: targeting.formattedEarnings,
                    color: .green
                )
                
                TargetingDetailedMetricRow(
                    icon: "target",
                    title: "Type",
                    value: targeting.displayTargetingType,
                    color: colorForTargeting
                )
                
                TargetingDetailedMetricRow(
                    icon: "info.circle.fill",
                    title: "Performance",
                    value: performanceDescription,
                    color: .secondary
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
    }
    
    private var expandButton: some View {
        HStack {
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetailedMetrics.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Text(showDetailedMetrics ? "Less Details" : "More Details")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Image(systemName: showDetailedMetrics ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            Spacer()
        }
    }
    
    // Helper computed properties
    private var colorForTargeting: Color {
        switch targeting.targetingColor.lowercased() {
        case "blue":
            return .blue
        case "green":
            return .green
        case "purple":
            return .purple
        case "orange":
            return .orange
        case "gray":
            return .gray
        case "pink":
            return .pink
        default:
            return .accentColor
        }
    }
    
    private var performanceDescription: String {
        guard let ctrValue = Double(targeting.ctr) else { return "N/A" }
        if ctrValue > 0.02 {
            return "High CTR"
        } else if ctrValue > 0.01 {
            return "Good CTR"
        } else {
            return "Low CTR"
        }
    }
}

struct TargetingMetricPill: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .fontWeight(.medium)
            
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TargetingDetailedMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 16, height: 16)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .fontWeight(.medium)
            }
            
            Text(value)
                .font(.system(.callout, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    TargetingCard(targeting: TargetingData(
        targetingType: "CONTEXTUAL",
        earnings: "12.34",
        impressions: "1234",
        clicks: "56",
        ctr: "0.045",
        rpm: "0.98"
    ))
    .padding()
} 