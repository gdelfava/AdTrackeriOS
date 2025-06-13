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
    
    var body: some View {
        if authViewModel.isSignedIn {
            SummaryTabView()
                .environmentObject(authViewModel)
        } else {
            VStack {
                Text("Sign in with Google")
                    .font(.title)
                    .padding()
                GoogleSignInButtonView()
                    .frame(width: 200, height: 50)
                    .onTapGesture {
                        authViewModel.signIn()
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
