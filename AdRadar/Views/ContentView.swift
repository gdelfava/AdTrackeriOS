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
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    
    var body: some View {
        ZStack {
            if authViewModel.isSignedIn {
                SummaryTabView()
                    .environmentObject(authViewModel)
            } else {
                ZStack {
                    Color("LoginScreenBackground")
                        .ignoresSafeArea()
                    VStack {
                        Spacer()
                        VStack(spacing: 24) {
                            Image("LoginScreen")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .accessibilityHidden(true)
                            VStack {
                                Text("AdRadar")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .fontDesign(.rounded)
                                    .foregroundColor(.white)
                                Text("for Adsense")
                                    .font(.caption)
                                    .fontWeight(.regular)
                                    .fontDesign(.rounded)
                                    .foregroundColor(.white)
                            }
                        }
                        Spacer()
                        GoogleSignInButtonView {
                            authViewModel.signIn()
                        }
                        .frame(maxWidth: 340)
                        .padding(.top, 16)
                        Spacer()
                        Button(action: { showWhyGoogle = true }) {
                            Text("Why do I need to sign in with Google?")
                                .font(.footnote)
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                        .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 24)
                }
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
    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Image("LoginScreen", bundle: nil)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .padding(.top, 24)
                    .shadow(radius: 4)
            }
            ScrollView {
                VStack(spacing: 16) {
                    Text("Why Google?")
                        .font(.title2).bold()
                        .foregroundColor(.black)
                        .padding(.top, 0)
                    Text("AdRadar requires you to sign in to your Google account to allow it to receive the relevant AdSense data.\n\nWithout this, AdRadar cannot provide you with any information.\n\nAdRadar does not store any personal information. It is used only to display your data.")
                        .font(.body)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            Spacer()
            Button(action: { isPresented = false }) {
                Text("OK")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(24)
            }
            .padding([.horizontal, .bottom], 24)
        }
        .background(Color.white)
        .cornerRadius(32)
        .padding(.top, 40)
        .padding(.horizontal, 8)
        .presentationDetents([.large])
    }
}

#Preview {
    ContentView()
}
