import SwiftUI
import MessageUI

struct SlideOverMenuView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Binding var selectedTab: Int // 0: Summary, 1: Streak, 2: Payments, 3: Settings
    @Binding var showDomainsView: Bool
    @Binding var showAdSizeView: Bool
    @Binding var showPlatformsView: Bool
    @Binding var showCountriesView: Bool
    @Binding var showAdNetworkView: Bool
    @Binding var showTargetingView: Bool
    @Binding var showAppsView: Bool
    @State private var showMail = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Menu content
                VStack(spacing: 0) {
                    // Header with user info - Modern gradient design
                    VStack(spacing: 0) {
                        // Header content with proper safe area handling
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(settingsViewModel.publisherName.isEmpty ? "Publisher Name" : settingsViewModel.publisherName)
                                        .soraTitle2()
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                    HStack(spacing: 8) {
                                        Image(systemName: "number.circle.fill")
                                            .font(.body)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Text(settingsViewModel.publisherId.isEmpty ? "1234567890" : settingsViewModel.publisherId)
                                            .soraBody()
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineLimit(1)
                                    }
                                    
                                    Text("AdSense Analytics")
                                        .soraCaption()
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                // Menu close indicator
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.6))
                                    .onTapGesture {
                                        dismissMenu()
                                    }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, max(60, geometry.safeAreaInsets.top + 40))
                            .padding(.bottom, 24)
                        }
                        .background(
                            ZStack {
                                // Base gradient matching app's accent color and design
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: colorScheme == .dark ? 
                                            Color.accentColor.opacity(0.7) : Color.accentColor.opacity(0.95), location: 0),
                                        .init(color: colorScheme == .dark ? 
                                            Color.accentColor.opacity(0.6) : Color.accentColor.opacity(0.85), location: 0.4),
                                        .init(color: colorScheme == .dark ? 
                                            Color.blue.opacity(0.5) : Color.blue.opacity(0.8), location: 0.7),
                                        .init(color: colorScheme == .dark ? 
                                            Color.indigo.opacity(0.4) : Color.indigo.opacity(0.75), location: 1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                
                                // Subtle overlay for depth matching app's style
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.clear, location: 0),
                                        .init(color: Color.black.opacity(colorScheme == .dark ? 0.15 : 0.08), location: 0.6),
                                        .init(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.15), location: 1)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .blendMode(.multiply)
                            }
                        )
                    }
                    
                    // Main content with modern sections
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Analytics Section
                            MenuSection(title: "Analytics", icon: "chart.bar.fill", iconColor: .blue) {
                                ModernMenuRow(
                                    icon: "globe.americas.fill", 
                                    title: "Domains", 
                                    subtitle: "Site performance",
                                    iconColor: .blue,
                                    action: {
                                        hapticFeedback()
                                        showDomainsView = true
                                        dismissMenu()
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
                                        dismissMenu()
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
                                        dismissMenu()
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
                                        dismissMenu()
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
                                        dismissMenu()
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
                                        dismissMenu()
                                    }
                                )
                                
                                ModernMenuRow(
                                    icon: "apps.iphone", 
                                    title: "AdMob Apps", 
                                    subtitle: "Mobile app metrics",
                                    iconColor: .cyan,
                                    action: {
                                        hapticFeedback()
                                        showAppsView = true
                                        dismissMenu()
                                    }
                                )
                            }
                            
                            // Account Section
                            MenuSection(title: "Account", icon: "person.circle.fill", iconColor: .green) {
                                ModernMenuRow(
                                    icon: "creditcard.fill", 
                                    title: "Payments", 
                                    subtitle: "Earnings & history",
                                    iconColor: .green,
                                    action: {
                                        hapticFeedback()
                                        selectedTab = 2
                                        dismissMenu()
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
                                        dismissMenu()
                                    }
                                )
                            }
                            
                            // Support Section
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
                            
                            // App info footer
                            VStack(spacing: 8) {
                                Text("AdRadar")
                                    .soraCaption()
                                    .foregroundColor(.secondary)
                                
                                Text("Not affiliated with Google or AdSense")
                                    .soraCaption2()
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 16)
                            .padding(.bottom, 32)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                    }
                    .background(Color(.systemGroupedBackground))
                }
                .frame(width: min(geometry.size.width * 0.85, 340), height: geometry.size.height)
                .background(Color(.systemGroupedBackground))
                .clipShape(
                    RoundedCornerShape(
                        radius: 0,
                        corners: [.topRight, .bottomRight]
                    )
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 5, y: 0)
                
                // Dismiss area
                Color.black.opacity(0.4)
                    .onTapGesture {
                        dismissMenu()
                    }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showMail) {
            MailView(
                toRecipients: ["apps@delteqis.co.za"],
                subject: "AdRadar: User feedback",
                body: "Any feedback or questions are more than welcome, please enter your message below:",
                completion: { _ in showMail = false }
            )
        }
    }
    
    private func hapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func dismissMenu() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isPresented = false
        }
    }
}

// Modern Menu Section with header
struct MenuSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: Content
    
    init(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                    .background(iconColor.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .soraSubheadline()
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Section content
            VStack(spacing: 0) {
                content
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// Modern Menu Row with enhanced design
struct ModernMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    var isDisabled: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Icon with background
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isDisabled ? iconColor.opacity(0.4) : iconColor)
                    .frame(width: 40, height: 40)
                    .background((isDisabled ? iconColor.opacity(0.1) : iconColor.opacity(0.15)))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                // Text content
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .soraBody()
                        .foregroundColor(isDisabled ? .secondary : .primary)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .soraCaption()
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Chevron or disabled indicator
                if isDisabled {
                    Text("Soon")
                        .soraCaption2()
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing && !isDisabled
            }
        }, perform: {})
    }
}

// Custom shape for rounded corners
struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Legacy components for compatibility
struct MenuRow: View {
    let icon: String
    let title: String
    var color: Color = .primary
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 24)
            Text(title)
                .soraBody()
                .foregroundColor(color)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct MenuItemView: View {
    let title: String
    let icon: String
    
    var body: some View {
        Button(action: {
            // Handle menu item tap
            print("Tapped: \(title)")
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 24)
                
                Text(title)
                    .soraBody()
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SlideOverMenuView(isPresented: .constant(true), selectedTab: .constant(0), showDomainsView: .constant(false), showAdSizeView: .constant(false), showPlatformsView: .constant(false), showCountriesView: .constant(false), showAdNetworkView: .constant(false), showTargetingView: .constant(false), showAppsView: .constant(false))
        .environmentObject(AuthViewModel())
        .environmentObject(SettingsViewModel(authViewModel: AuthViewModel()))
} 