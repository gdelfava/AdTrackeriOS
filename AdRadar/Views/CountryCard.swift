import SwiftUI

struct CountryCard: View {
    let country: CountryData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with Country Flag, Name and Earnings
            HStack {
                Text(country.formattedEarnings)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(country.flagEmoji)
                    .font(.title2)
                
                Text(country.displayCountryName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            // Metrics Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                CountryMetricRow(title: "Requests", value: country.requests)
                CountryMetricRow(title: "Page Views", value: country.pageViews)
                CountryMetricRow(title: "Impressions", value: country.impressions)
                CountryMetricRow(title: "Clicks", value: country.clicks)
                CountryMetricRow(title: "CTR", value: country.formattedCTR)
                CountryMetricRow(title: "RPM", value: country.formattedRPM)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct CountryMetricRow: View {
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
