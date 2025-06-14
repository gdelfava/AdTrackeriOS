import SwiftUI

struct SummaryTabView: View {
    var body: some View {
        TabView {
            SummaryView()
                .tabItem {
                    Image(systemName: "square.split.2x2")
                    Text("Summary")
                }
            PaymentsView()
                .tabItem {
                    Image(systemName: "creditcard")
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
