import SwiftUI

struct SummaryTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var showSlideOverMenu = false
    @State private var selectedTab: Int = 0
    
    init() {
        // We'll initialize settingsViewModel in onAppear to ensure we have access to authViewModel
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                SummaryView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Summary")
                    }
                    .tag(0)
                StreakView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "7.square.fill")
                        Text("Streak")
                    }
                    .tag(1)
                PaymentsView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "creditcard")
                        Text("Payments")
                    }
                    .tag(2)
                SettingsView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(3)
            }
            .environmentObject(settingsViewModel)
            .onAppear {
                // Update settingsViewModel with the correct authViewModel
                settingsViewModel.authViewModel = authViewModel
            }
            
            // Slide-over menu
            if showSlideOverMenu {
                SlideOverMenuView(isPresented: $showSlideOverMenu, selectedTab: $selectedTab)
                    .environmentObject(authViewModel)
                    .environmentObject(settingsViewModel)
                    .transition(.move(edge: .leading))
                    .zIndex(1)
            }
        }
    }
}

#Preview {
    SummaryTabView()
        .environmentObject(AuthViewModel())
} 
