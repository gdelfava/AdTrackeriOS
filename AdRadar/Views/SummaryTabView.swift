import SwiftUI

struct SummaryTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @State private var showSlideOverMenu = false
    @State private var selectedTab: Int = 0
    @State private var showDomainsView = false
    @State private var showAdSizeView = false
    @State private var showPlatformsView = false
    @State private var showCountriesView = false
    @State private var showAdNetworkView = false
    
    init() {
        // We'll initialize settingsViewModel in onAppear to ensure we have access to authViewModel
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        ZStack {
            // Edge swipe area for opening menu
            Color.clear
                .frame(width: 28)
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .gesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.width > 20 && abs(value.translation.height) < 40 {
                                withAnimation { showSlideOverMenu = true }
                            }
                        }
                )
                .zIndex(2)
            
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
            .gesture(
                DragGesture(minimumDistance: 15, coordinateSpace: .global)
                    .onEnded { value in
                        // Only trigger if drag starts near left edge and is a rightward swipe
                        if value.startLocation.x < 28 && value.translation.width > 20 && abs(value.translation.height) < 40 {
                            withAnimation { showSlideOverMenu = true }
                        }
                    }
            )
            
            // Slide-over menu
            if showSlideOverMenu {
                SlideOverMenuView(
                    isPresented: $showSlideOverMenu, 
                    selectedTab: $selectedTab,
                    showDomainsView: $showDomainsView,
                    showAdSizeView: $showAdSizeView,
                    showPlatformsView: $showPlatformsView,
                    showCountriesView: $showCountriesView,
                    showAdNetworkView: $showAdNetworkView
                )
                .environmentObject(authViewModel)
                .environmentObject(settingsViewModel)
                .transition(.move(edge: .leading))
                .zIndex(1)
                .gesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .global)
                        .onEnded { value in
                            // Only trigger if drag is leftward and starts near left edge of menu
                            if value.translation.width < -20 && abs(value.translation.height) < 40 {
                                withAnimation { showSlideOverMenu = false }
                            }
                        }
                )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8, blendDuration: 0.1), value: showSlideOverMenu)
        .fullScreenCover(isPresented: $showDomainsView) {
            DomainsView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showAdSizeView) {
            AdSizeView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showPlatformsView) {
            PlatformView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showCountriesView) {
            CountriesView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
        .fullScreenCover(isPresented: $showAdNetworkView) {
            AdNetworkView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
    }
}

#Preview {
    SummaryTabView()
        .environmentObject(AuthViewModel())
} 
