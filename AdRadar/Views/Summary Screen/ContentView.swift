// Main content view for AdRadar
//
//  ContentView.swift
//  AdRadar
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import SwiftUI
import GoogleSignIn
import UIKit

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

#Preview {
    ContentView()
}
