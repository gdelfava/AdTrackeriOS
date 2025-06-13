import SwiftUI

struct SummaryTabView: View {
    var body: some View {
        TabView {
            SummaryView()
                .tabItem {
                    Image(systemName: "chart.bar.xaxis")
                    Text("Summary")
                }
            PaymentsView()
                .tabItem {
                    Image(systemName: "dollarsign.circle")
                    Text("Payments")
                }
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
    }
}

#Preview {
    SummaryTabView()
} 