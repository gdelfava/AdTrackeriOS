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
    
    var body: some View {
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
                        Image("LoginScreen", bundle: nil)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .accessibilityHidden(true)
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
                            .font(.body)
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 24)
            }
            .sheet(isPresented: $showWhyGoogle) {
                WhyGoogleModal(isPresented: $showWhyGoogle)
            }
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
                    Text("AdsenseTracker requires you to sign in to your Google account to allow it to receive the relevant AdSense data.\n\nWithout this, AdTracker cannot provide you with any information.\n\nAdTracker does not store any personal information. It is used only to display your data.")
                        .font(.body)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
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
                    .background(Color.loginScreenBackground)
                    .cornerRadius(24)
            }
            .padding([.horizontal, .bottom], 24)
        }
        .background(Color.white)
        .cornerRadius(32)
        .padding(.top, 40)
        .padding(.horizontal, 8)
        .presentationDetents([.height(500)])
    }
}

#Preview {
    ContentView()
}
