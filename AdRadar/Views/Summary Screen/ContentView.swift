// Main content view for AdRadar
//
//  ContentView.swift
//  AdRadar
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import SwiftUI
import GoogleSignIn

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showWhyGoogle = false
    @State private var showOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding") == false
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    
    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
                    .onDisappear {
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    }
            } else if authViewModel.isSignedIn {
                SummaryTabView()
                    .environmentObject(authViewModel)
            } else {
                ModernSignInView(
                    authViewModel: authViewModel,
                    showWhyGoogle: $showWhyGoogle
                )
            }
        }
        .sheet(isPresented: $showWhyGoogle) {
            WhyGoogleModal(isPresented: $showWhyGoogle)
        }
        .sheet(isPresented: $networkMonitor.showNetworkErrorModal) {
            NetworkErrorModalView(
                message: "The Internet connection appears to be offline. Please check your Wi-Fi or Cellular settings.",
                onClose: { networkMonitor.showNetworkErrorModal = false },
                onSettings: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            )
        }
    }
}

// MARK: - Why Google Modal
struct WhyGoogleModal: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var animateContent = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(0.1), value: animateContent)
            
            // Header section with icon
            VStack(spacing: 24) {
                // Modern icon treatment
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateContent ? 1.0 : 0.6)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.accentColor)
                        .scaleEffect(animateContent ? 1.0 : 0.4)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                .animation(.easeOut(duration: 1.0).delay(0.3), value: animateContent)
                
                // Title
                Text("Why Google Sign-In?")
                    .font(.sora(.bold, size: 24))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: animateContent)
            }
            .padding(.top, 24)
            
            // Content sections
            ScrollView {
                VStack(spacing: 24) {
                    // Security section
                    InfoSection(
                        icon: "lock.shield",
                        iconColor: .green,
                        title: "Secure & Private",
                        description: "AdRadar uses Google's secure OAuth system to safely access only your AdSense data.",
                        animateContent: animateContent,
                        delay: 0.8
                    )
                    
                    // Data section
                    InfoSection(
                        icon: "chart.bar.fill",
                        iconColor: .accentColor,
                        title: "Real AdSense Data",
                        description: "We need access to your AdSense account to provide accurate earnings and performance analytics.",
                        animateContent: animateContent,
                        delay: 1.0
                    )
                    
                    // Privacy section
                    InfoSection(
                        icon: "hand.raised.fill",
                        iconColor: .purple,
                        title: "No Data Storage",
                        description: "AdRadar doesn't store your personal information. Data is only used to display your analytics.",
                        animateContent: animateContent,
                        delay: 1.2
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
            
            // Action button
            VStack(spacing: 16) {
                Button(action: { 
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    isPresented = false 
                }) {
                    Text("Got it!")
                        .font(.sora(.semibold, size: 17))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ModernButtonStyle())
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(1.6), value: animateContent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                animateContent = true
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Info Section Component
struct InfoSection: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let animateContent: Bool
    let delay: Double
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.sora(.semibold, size: 16))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.sora(.regular, size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .opacity(animateContent ? 1.0 : 0.0)
        .offset(y: animateContent ? 0 : 30)
        .animation(.easeOut(duration: 0.8).delay(delay), value: animateContent)
    }
}

// MARK: - Modern Sign-In View
struct ModernSignInView: View {
    let authViewModel: AuthViewModel
    @Binding var showWhyGoogle: Bool
    @State private var animateContent = false
    @State private var showSignInButton = false
    @State private var animateFloatingElements = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Modern gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color.accentColor.opacity(0.1),
                        Color(.systemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Floating elements for visual interest
                FloatingElementsView(animate: $animateFloatingElements)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Top spacing
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: max(geometry.safeAreaInsets.top + 10, 20))
                        
                        // Main content
                        VStack(spacing: 32) {
                            // Header section
                            VStack(spacing: 24) {
                                // App branding with modern circles (no icon)
                                ZStack {
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.1))
                                        .frame(width: 200, height: 200)
                                        .scaleEffect(animateContent ? 1.0 : 0.8)
                                        .opacity(animateContent ? 1.0 : 0.0)
                                    
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.15))
                                        .frame(width: 160, height: 160)
                                        .scaleEffect(animateContent ? 1.0 : 0.6)
                                        .opacity(animateContent ? 1.0 : 0.0)
                                    
                                    // Central radar icon
                                    ZStack {
                                        Circle()
                                            .fill(Color.accentColor.opacity(0.9))
                                            .frame(width: 100, height: 100)
                                        
                                                                                 Image(systemName: "target")
                                             .font(.system(size: 40, weight: .semibold))
                                             .foregroundColor(.white)
                                    }
                                    .scaleEffect(animateContent ? 1.0 : 0.4)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                    
                                    // Pulsing effect
                                    Circle()
                                        .fill(Color.accentColor.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                        .scaleEffect(animateContent ? 1.4 : 0.4)
                                        .opacity(animateContent ? 0.0 : 0.8)
                                        .animation(.easeOut(duration: 2.0).repeatForever(autoreverses: true), value: animateContent)
                                }
                                .animation(.easeOut(duration: 1.2).delay(0.3), value: animateContent)
                                
                                // App title and description
                                VStack(spacing: 16) {
                                    VStack(spacing: 8) {
                                        Text("AdRadar")
                                            .font(.sora(.bold, size: 48))
                                            .foregroundColor(.primary)
                                            .opacity(animateContent ? 1.0 : 0.0)
                                            .offset(y: animateContent ? 0 : 30)
                                            .animation(.easeOut(duration: 0.8).delay(0.8), value: animateContent)
                                        
                                        Text("for AdSense")
                                            .font(.sora(.medium, size: 20))
                                            .foregroundColor(.secondary)
                                            .opacity(animateContent ? 1.0 : 0.0)
                                            .offset(y: animateContent ? 0 : 20)
                                            .animation(.easeOut(duration: 0.8).delay(1.0), value: animateContent)
                                    }
                                    
                                                                        Text("Track your earnings with beautiful analytics and detailed insights")
                                        .font(.sora(.regular, size: 18))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 40)
                                        .opacity(animateContent ? 1.0 : 0.0)
                                        .offset(y: animateContent ? 0 : 30)
                                        .animation(.easeOut(duration: 0.8).delay(1.2), value: animateContent)
                                }
                            }
                            
                            // Spacer to push sign-in button to bottom
                            Spacer()
                            
                            // Sign in section
                            VStack(spacing: 16) {
                                // Modern Google Sign In Button
                                Button(action: {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    authViewModel.signIn()
                                }) {
                                    HStack(spacing: 16) {
                                        // Google Sign In icon
                                        Image("GoogleSignIn")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 24, height: 24)
                                        
                                        Text("Continue with Google")
                                            .font(.sora(.semibold, size: 17))
                                            .foregroundColor(.primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .shadow(color: Color.primary.opacity(0.1), radius: 12, x: 0, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(ModernButtonStyle())
                                .scaleEffect(showSignInButton ? 1.0 : 0.8)
                                .opacity(showSignInButton ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.6).delay(1.4), value: showSignInButton)
                                
                                // Info text
                                Button(action: { 
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    showWhyGoogle = true 
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("Why Google Sign-In?")
                                            .font(.sora(.medium, size: 14))
                                    }
                                    .foregroundColor(.secondary)
                                }
                                .opacity(showSignInButton ? 1.0 : 0.0)
                                .animation(.easeOut(duration: 0.6).delay(1.6), value: showSignInButton)
                            }
                            .padding(.horizontal, 32)
                        }
                        
                        // Bottom spacing
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: max(geometry.safeAreaInsets.bottom + 50, 80))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
                animateFloatingElements = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(2.0)) {
                showSignInButton = true
            }
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.accentColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.sora(.semibold, size: 16))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.sora(.regular, size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .opacity(animate ? 1.0 : 0.0)
        .offset(x: animate ? 0 : -30)
        .animation(.easeOut(duration: 0.6).delay(delay), value: animate)
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Floating Elements
struct FloatingElementsView: View {
    @Binding var animate: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Floating circles
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.3)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.0).delay(0.5), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.05))
                    .frame(width: 80, height: 80)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.5).delay(1.0), value: animate)
                
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 40, height: 40)
                    .position(x: geometry.size.width * 0.1, y: geometry.size.height * 0.7)
                    .scaleEffect(animate ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 2.2).delay(1.5), value: animate)
            }
        }
    }
}

// MARK: - Modern Button Style
struct ModernButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ContentView()
}
