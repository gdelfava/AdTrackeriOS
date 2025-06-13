import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel // Assumes you have an AuthViewModel for login state
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // User Info
                    VStack(spacing: 8) {
                        if let url = viewModel.imageURL {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                    .shadow(radius: 7)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            }
                        }
                        Text(viewModel.name)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(viewModel.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)
                    
                    // Support Section
                    Section(header: Text("SUPPORT").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)) {
                        VStack(spacing: 0) {
                            settingsRow(icon: "heart.fill", color: .red, title: "Rate MyAds")
                            settingsRow(icon: "square.and.arrow.up", color: .yellow, title: "Share MyAds")
                            settingsRow(icon: "envelope.fill", color: .blue, title: "Feedback")
                            settingsRow(icon: "gearshape.fill", color: .gray, title: "Widget Support")
                            settingsRow(icon: "bird.fill", color: .blue, title: "@MyAds")
                            settingsRow(icon: "lock.fill", color: .purple, title: "Terms & Privacy Policy")
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // General Section
                    Section(header: Text("GENERAL").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)) {
                        VStack(spacing: 0) {
                            Button(action: {
                                viewModel.signOut()
                                authViewModel.signOut() // Assumes this triggers login screen
                            }) {
                                HStack {
                                    Image(systemName: "person.crop.circle.fill.badge.xmark")
                                        .foregroundColor(.red)
                                    Text("Sign Out")
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding()
                            }
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Settings")
            .background(Color.black.ignoresSafeArea())
            .onChange(of: viewModel.isSignedOut) { signedOut, _ in
                if signedOut {
                    authViewModel.isSignedIn = false
                }
            }
        }
    }
    
    @ViewBuilder
    private func settingsRow(icon: String, color: Color, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .foregroundColor(.primary)
            Spacer()
        }
        .padding()
    }
}

// For preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
} 
