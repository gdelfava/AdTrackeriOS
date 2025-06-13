import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = SettingsViewModel(authViewModel: AuthViewModel())
    
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
                                    .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 4))
                                    .shadow(radius: 3)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            }
                        }
                        Text(viewModel.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text(viewModel.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)
                    
                    // Support Section
                    Section(header: Text("SUPPORT").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)) {
                        VStack(spacing: 0) {
                            settingsRow(icon: "heart.fill", color: .red, title: "Rate AdTracker")
                            settingsRow(icon: "square.and.arrow.up", color: .yellow, title: "Share AdTracker")
                            settingsRow(icon: "envelope.fill", color: .blue, title: "Feedback")
                            settingsRow(icon: "bird.fill", color: .blue, title: "@AdTracker")
                            settingsRow(icon: "lock.fill", color: .purple, title: "Terms & Privacy Policy")
                        }
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    
                    // General Section
                    Section(header: Text("GENERAL").font(.caption).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .leading)) {
                        VStack(spacing: 0) {
                            Button(action: {
                                viewModel.signOut(authViewModel: authViewModel)
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
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Settings")
            .background(Color(.systemBackground).ignoresSafeArea())
            .onChange(of: viewModel.isSignedOut) { signedOut, _ in
                if signedOut {
                    authViewModel.isSignedIn = false
                }
            }
            .onAppear {
                // Update viewModel with the real authViewModel's user info
                viewModel.name = authViewModel.userName
                viewModel.email = authViewModel.userEmail
                viewModel.imageURL = authViewModel.userProfileImageURL
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
            .preferredColorScheme(.light)
        SettingsView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
} 
