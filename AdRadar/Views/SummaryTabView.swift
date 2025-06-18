import SwiftUI

struct SummaryTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    
    init() {
        // We'll initialize settingsViewModel in onAppear to ensure we have access to authViewModel
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(authViewModel: AuthViewModel()))
    }
    
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
        .environmentObject(settingsViewModel)
        .onAppear {
            // Update settingsViewModel with the correct authViewModel
            settingsViewModel.authViewModel = authViewModel
        }
    }
}

#Preview {
    SummaryTabView()
        .environmentObject(AuthViewModel())
} 
