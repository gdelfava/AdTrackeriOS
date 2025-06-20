// Main content view for Adsense Tracker
//
//  ContentView.swift
//  Adsense Tracker
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
                        .fill(Color(.systemBlue).opacity(0.1))
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Circle()
                        .fill(Color(.systemBlue).opacity(0.15))
                        .frame(width: 80, height: 80)
                        .scaleEffect(animateContent ? 1.0 : 0.6)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.blue)
                        .scaleEffect(animateContent ? 1.0 : 0.4)
                        .opacity(animateContent ? 1.0 : 0.0)
                }
                .animation(.easeOut(duration: 1.0).delay(0.3), value: animateContent)
                
                // Title
                Text("Why Google Sign-In?")
                    .font(.title2.weight(.bold))
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
                        iconColor: .blue,
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
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(.systemBlue), Color(.systemPurple)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

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
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.body)
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

struct ModernSignInView: View {
    let authViewModel: AuthViewModel
    @Binding var showWhyGoogle: Bool
    @State private var animateContent = false
    @State private var showSignInButton = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Modern gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBlue).opacity(0.8),
                        Color(.systemPurple).opacity(0.6),
                        Color(.systemIndigo).opacity(0.9)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Background pattern/decoration
                VStack {
                    Spacer()
                    
                    // Main content
                    VStack(spacing: 0) {
                        // Logo and branding section
                        VStack(spacing: 32) {
                            // App icon with layered circles (matching onboarding style)
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 200, height: 200)
                                    .scaleEffect(animateContent ? 1.0 : 0.8)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 160, height: 160)
                                    .scaleEffect(animateContent ? 1.0 : 0.6)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .scaleEffect(animateContent ? 1.0 : 0.4)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                
                                Image("LoginScreen")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .scaleEffect(animateContent ? 1.0 : 0.2)
                                    .opacity(animateContent ? 1.0 : 0.0)
                            }
                            .animation(.easeOut(duration: 1.2).delay(0.3), value: animateContent)
                            
                            // App title and description
                            VStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    Text("AdRadar")
                                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                        .foregroundColor(.white)
                                        .opacity(animateContent ? 1.0 : 0.0)
                                        .offset(y: animateContent ? 0 : 30)
                                        .animation(.easeOut(duration: 0.8).delay(0.8), value: animateContent)
                                    
                                    Text("for AdSense")
                                        .font(.title2.weight(.medium))
                                        .foregroundColor(.white.opacity(0.9))
                                        .opacity(animateContent ? 1.0 : 0.0)
                                        .offset(y: animateContent ? 0 : 20)
                                        .animation(.easeOut(duration: 0.8).delay(1.0), value: animateContent)
                                }
                                
                                Text("Track your earnings with beautiful analytics")
                                    .font(.title3)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 40)
                                    .opacity(animateContent ? 1.0 : 0.0)
                                    .offset(y: animateContent ? 0 : 30)
                                    .animation(.easeOut(duration: 0.8).delay(1.2), value: animateContent)
                            }
                        }
                        
                        Spacer()
                        
                        // Sign in section
                        VStack(spacing: 24) {
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
                                        .font(.body.weight(.semibold))
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                )
                            }
                            .buttonStyle(ModernButtonStyle())
                            .scaleEffect(showSignInButton ? 1.0 : 0.8)
                            .opacity(showSignInButton ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.6).delay(1.6), value: showSignInButton)
                            
                            // Info button
                            Button(action: { 
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                showWhyGoogle = true 
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Why Google Sign-In?")
                                        .font(.body.weight(.medium))
                                }
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Capsule())
                            }
                            .opacity(showSignInButton ? 1.0 : 0.0)
                            .animation(.easeOut(duration: 0.6).delay(1.8), value: showSignInButton)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, max(geometry.safeAreaInsets.bottom + 32, 48))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateContent = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(1.4)) {
                showSignInButton = true
            }
        }
    }
}

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
