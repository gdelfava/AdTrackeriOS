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
    @State private var showTargetingView = false
    @State private var previousSelectedTab: Int = 0
    
    init() {
        // We'll initialize settingsViewModel in onAppear to ensure we have access to authViewModel
        _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(authViewModel: AuthViewModel()))
    }
    
    var body: some View {
        ZStack {
            // Main content area
            VStack(spacing: 0) {
                // Content view that changes based on selected tab
                ZStack {
                    // Edge swipe area for opening menu
                    VStack {
                        HStack {
                            Color.clear
                                .frame(width: 28)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 15, coordinateSpace: .local)
                                        .onEnded { value in
                                            if value.translation.width > 20 && abs(value.translation.height) < 40 {
                                                withAnimation { showSlideOverMenu = true }
                                            }
                                        }
                                )
                                .zIndex(2)
                            Spacer()
                        }
                        Spacer()
                    }
                    
                    // Tab content with slide animation
                    Group {
                        if selectedTab == 0 {
                            SummaryView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                                .transition(.asymmetric(
                                    insertion: .move(edge: previousSelectedTab < selectedTab ? .trailing : .leading).combined(with: .opacity),
                                    removal: .move(edge: previousSelectedTab < selectedTab ? .leading : .trailing).combined(with: .opacity)
                                ))
                        } else if selectedTab == 1 {
                            StreakView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                                .transition(.asymmetric(
                                    insertion: .move(edge: previousSelectedTab < selectedTab ? .trailing : .leading).combined(with: .opacity),
                                    removal: .move(edge: previousSelectedTab < selectedTab ? .leading : .trailing).combined(with: .opacity)
                                ))
                        } else if selectedTab == 2 {
                            PaymentsView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                                .transition(.asymmetric(
                                    insertion: .move(edge: previousSelectedTab < selectedTab ? .trailing : .leading).combined(with: .opacity),
                                    removal: .move(edge: previousSelectedTab < selectedTab ? .leading : .trailing).combined(with: .opacity)
                                ))
                        } else if selectedTab == 3 {
                            SettingsView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                                .transition(.asymmetric(
                                    insertion: .move(edge: previousSelectedTab < selectedTab ? .trailing : .leading).combined(with: .opacity),
                                    removal: .move(edge: previousSelectedTab < selectedTab ? .leading : .trailing).combined(with: .opacity)
                                ))
                        }
                    }
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
                
                // Floating Tab Bar
                FloatingTabBar(selectedTab: $selectedTab, previousSelectedTab: $previousSelectedTab)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
            
            // Slide-over menu
            if showSlideOverMenu {
                SlideOverMenuView(
                    isPresented: $showSlideOverMenu, 
                    selectedTab: $selectedTab,
                    showDomainsView: $showDomainsView,
                    showAdSizeView: $showAdSizeView,
                    showPlatformsView: $showPlatformsView,
                    showCountriesView: $showCountriesView,
                    showAdNetworkView: $showAdNetworkView,
                    showTargetingView: $showTargetingView
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
        .fullScreenCover(isPresented: $showTargetingView) {
            TargetingView(showSlideOverMenu: $showSlideOverMenu, selectedTab: $selectedTab)
                .environmentObject(authViewModel)
        }
    }
}

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    @Binding var previousSelectedTab: Int
    @Environment(\.colorScheme) private var colorScheme
    @State private var tabBarOffset: CGFloat = 60
    
    let tabItems: [(icon: String, activeIcon: String, title: String, tag: Int)] = [
        ("chart.bar", "chart.bar.fill", "Summary", 0),
        ("7.square", "7.square.fill", "Streak", 1),
        ("creditcard", "creditcard.fill", "Payments", 2),
        ("gearshape", "gearshape.fill", "Settings", 3)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabItems.enumerated()), id: \.element.tag) { index, item in
                TabBarButton(
                    icon: item.icon,
                    activeIcon: item.activeIcon,
                    title: item.title,
                    isSelected: selectedTab == item.tag,
                    action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        if selectedTab != item.tag {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                previousSelectedTab = selectedTab
                                selectedTab = item.tag
                            }
                        }
                    }
                )
                
                if index < tabItems.count - 1 {
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 12, x: 0, y: 4)
        .offset(y: tabBarOffset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                tabBarOffset = 0
            }
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let activeIcon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: isSelected ? activeIcon : icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(height: 24)
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 50)
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isPressed)
            .animation(.easeInOut(duration: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

#Preview {
    SummaryTabView()
        .environmentObject(AuthViewModel())
} 
