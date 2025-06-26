import SwiftUI

/// Analytics section of the slide over menu
struct AnalyticsMenuSection: View {
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    let onDismiss: () -> Void
    @Binding var showDomainsView: Bool
    @Binding var showAdSizeView: Bool
    @Binding var showPlatformsView: Bool
    @Binding var showCountriesView: Bool
    @Binding var showAdNetworkView: Bool
    @Binding var showTargetingView: Bool
    @Binding var showAppsView: Bool
    
    var body: some View {
        MenuSection(title: "Analytics", icon: "chart.bar.fill", iconColor: .blue) {
            ModernMenuRow(
                icon: "globe.americas.fill", 
                title: "Domains", 
                subtitle: "Site performance",
                iconColor: .blue,
                action: {
                    hapticFeedback()
                    showDomainsView = true
                    onDismiss()
                }
            )
            
            ModernMenuRow(
                icon: "rectangle.3.group.fill", 
                title: "Ad Sizes", 
                subtitle: "Format metrics",
                iconColor: .purple,
                action: {
                    hapticFeedback()
                    showAdSizeView = true
                    onDismiss()
                }
            )
            
            ModernMenuRow(
                icon: "iphone", 
                title: "Platforms", 
                subtitle: "Device breakdown",
                iconColor: .green,
                action: {
                    hapticFeedback()
                    showPlatformsView = true
                    onDismiss()
                }
            )
            
            ModernMenuRow(
                icon: "flag.fill", 
                title: "Countries", 
                subtitle: "Geographic data",
                iconColor: .orange,
                action: {
                    hapticFeedback()
                    showCountriesView = true
                    onDismiss()
                }
            )
            
            ModernMenuRow(
                icon: "network", 
                title: "Ad Networks", 
                subtitle: "Network performance",
                iconColor: .indigo,
                action: {
                    hapticFeedback()
                    showAdNetworkView = true
                    onDismiss()
                }
            )
            
            ModernMenuRow(
                icon: "target", 
                title: "Targeting", 
                subtitle: "Type performance",
                iconColor: .pink,
                action: {
                    hapticFeedback()
                    showTargetingView = true
                    onDismiss()
                }
            )
            
            if settingsViewModel.showAdMobApps {
                ModernMenuRow(
                    icon: "apps.iphone", 
                    title: "AdMob Apps", 
                    subtitle: "Mobile app metrics",
                    iconColor: .cyan,
                    action: {
                        hapticFeedback()
                        showAppsView = true
                        onDismiss()
                    }
                )
            }
        }
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

/// Account section of the slide over menu
struct AccountMenuSection: View {
    @Binding var selectedTab: Int
    let onDismiss: () -> Void
    
    var body: some View {
        MenuSection(title: "Account", icon: "person.circle.fill", iconColor: .green) {
            ModernMenuRow(
                icon: "creditcard.fill", 
                title: "Payments", 
                subtitle: "Earnings & history",
                iconColor: .green,
                action: {
                    hapticFeedback()
                    selectedTab = 2
                    onDismiss()
                }
            )
            
            ModernMenuRow(
                icon: "gearshape.fill", 
                title: "Settings", 
                subtitle: "App preferences",
                iconColor: .gray,
                action: {
                    hapticFeedback()
                    selectedTab = 3
                    onDismiss()
                }
            )
        }
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

/// Support section of the slide over menu
struct SupportMenuSection: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showMail: Bool
    
    var body: some View {
        MenuSection(title: "Support", icon: "questionmark.circle.fill", iconColor: .orange) {
            ModernMenuRow(
                icon: "envelope.fill", 
                title: "Send Feedback", 
                subtitle: "Help us improve",
                iconColor: .blue,
                action: {
                    hapticFeedback()
                    showMail = true
                }
            )
            
            // TODO: Re-enable when app is published to App Store
            /*
            ModernMenuRow(
                icon: "star.fill", 
                title: "Rate App", 
                subtitle: "Share your experience",
                iconColor: .yellow,
                action: {
                    hapticFeedback()
                    if let url = URL(string: "https://apps.apple.com/us/app/myads-adsense-admob/id1481431267?action=write-review") {
                        UIApplication.shared.open(url)
                    }
                }
            )
            */
            
            ModernMenuRow(
                icon: "rectangle.portrait.and.arrow.right", 
                title: "Sign Out", 
                subtitle: "Exit your account",
                iconColor: .red,
                action: {
                    hapticFeedback()
                    authViewModel.signOut()
                }
            )
        }
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    VStack(spacing: 20) {
        AnalyticsMenuSection(
            onDismiss: {},
            showDomainsView: .constant(false),
            showAdSizeView: .constant(false),
            showPlatformsView: .constant(false),
            showCountriesView: .constant(false),
            showAdNetworkView: .constant(false),
            showTargetingView: .constant(false),
            showAppsView: .constant(false)
        )
        .environmentObject(SettingsViewModel(authViewModel: AuthViewModel()))
        
        AccountMenuSection(selectedTab: .constant(0), onDismiss: {})
        
        SupportMenuSection(showMail: .constant(false))
            .environmentObject(AuthViewModel())
    }
    .padding()
} 