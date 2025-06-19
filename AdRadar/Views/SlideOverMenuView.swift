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
    @State private var showMail = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Menu content
                VStack(spacing: 0) {
                    // Header with user info
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            ProfileImageView(url: authViewModel.userProfileImageURL)
                                .frame(width: 48, height: 48)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(settingsViewModel.publisherName.isEmpty ? "Publisher Name" : settingsViewModel.publisherName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text(settingsViewModel.publisherId.isEmpty ? "1234567890" : settingsViewModel.publisherId)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 44)
                    .background(Color.accentColor)
                    .ignoresSafeArea(edges: .top)
                    
                    // Main menu items
                    VStack(spacing: 0) {
                        Button(action: {
                            showDomainsView = true
                            isPresented = false
                        }) {
                            MenuItemView(title: "Domain", icon: "globe")
                        }
                        Button(action: {
                            showAdSizeView = true
                            isPresented = false
                        }) {
                            MenuItemView(title: "Ad Size", icon: "rectangle.3.group")
                        }
                        Button(action: {
                            showPlatformsView = true
                            isPresented = false
                        }) {
                            MenuItemView(title: "Platforms", icon: "iphone")
                        }
                        MenuItemView(title: "Ad Network", icon: "network")
                        MenuItemView(title: "Country", icon: "flag")
                        MenuItemView(title: "Targeting", icon: "target")
                    }

                    // Section 1: Payments, Feedback, Write a Review
                    Divider().padding(.vertical, 8)
                    VStack(spacing: 0) {
                        Button(action: {
                            selectedTab = 2 // Payments tab
                            withAnimation { isPresented = false }
                        }) {
                            MenuRow(icon: "creditcard", title: "Payments")
                        }
                        Button(action: {
                            showMail = true
                        }) {
                            MenuRow(icon: "envelope", title: "Feedback")
                        }
                        Button(action: {
                            if let url = URL(string: "https://apps.apple.com/us/app/myads-adsense-admob/id1481431267?action=write-review") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            MenuRow(icon: "star.bubble", title: "Write a Review")
                        }
                    }
                    .sheet(isPresented: $showMail) {
                        MailView(
                            toRecipients: ["apps@delteqis.co.za"],
                            subject: "AdRadar: User feedback",
                            body: "Any feedback or questions are more than welcome, please enter your message below:",
                            completion: { _ in showMail = false }
                        )
                    }

                    // Section 2: Settings, Sign Out
                    Divider().padding(.vertical, 8)
                    VStack(spacing: 0) {
                        Button(action: {
                            selectedTab = 3 // Settings tab
                            withAnimation { isPresented = false }
                        }) {
                            MenuRow(icon: "gearshape", title: "Settings")
                        }
                        Button(action: {
                            authViewModel.signOut()
                        }) {
                            MenuRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign Out", color: .red)
                        }
                    }

                    Spacer()
                }
                .frame(width: min(geometry.size.width * 0.8, 320), height: geometry.size.height)
                .background(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 2, y: 0)
                
                // Dismiss area
                Color.black.opacity(0.3)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }
            }
        }
        .ignoresSafeArea()
    }
}

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
                .font(.body)
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
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            // No background, no shadow, no divider for flat design
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SlideOverMenuView(isPresented: .constant(true), selectedTab: .constant(0), showDomainsView: .constant(false), showAdSizeView: .constant(false), showPlatformsView: .constant(false))
        .environmentObject(AuthViewModel())
        .environmentObject(SettingsViewModel(authViewModel: AuthViewModel()))
} 