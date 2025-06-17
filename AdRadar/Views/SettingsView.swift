import SwiftUI
import MessageUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @State private var isShareSheetPresented = false
    @State private var isWidgetSupportSheetPresented = false
    @State private var isMailSheetPresented = false
    @State private var isTermsSheetPresented = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // User Profile Section
                    VStack(spacing: 16) {
                        if let url = settingsViewModel.imageURL {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color(.systemBackground), lineWidth: 4)
                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    )
                                    .onAppear {
                                        Task {
                                            await ImageCache.shared.setImage(image, for: url)
                                        }
                                    }
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            Text(settingsViewModel.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text(settingsViewModel.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 24)
                    
                    // Support Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SUPPORT")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            // AnimatedSettingsRow(icon: "heart.fill", color: .red, title: "Rate AdRadar") {
                            //     if let url = URL(string: "itms-apps://itunes.apple.com/app/id1481431267?action=write-review") {
                            //         UIApplication.shared.open(url)
                            //     }
                            // }
                            // Divider()
                            // AnimatedSettingsRow(icon: "square.and.arrow.up", color: .blue, title: "Share AdRadar") {
                            //     isShareSheetPresented = true
                            // }
                            // Divider()
                            AnimatedSettingsRow(icon: "square.grid.2x2.fill", color: .orange, title: "Widget Support") {
                                isWidgetSupportSheetPresented = true
                            }
                            Divider()
                            AnimatedSettingsRow(icon: "envelope.fill", color: .green, title: "Feedback") {
                                isMailSheetPresented = true
                            }
                            Divider()
                            AnimatedSettingsRow(icon: "bird.fill", color: .blue, title: "@AdRadar") {
                                if let url = URL(string: "https://x.com/gdelfava") {
                                    UIApplication.shared.open(url)
                                }
                            }
                            Divider()
                            AnimatedSettingsRow(icon: "lock.fill", color: .purple, title: "Terms & Privacy Policy") {
                                isTermsSheetPresented = true
                            }
                            Divider()
                            Toggle(isOn: Binding(
                                get: { settingsViewModel.isHapticFeedbackEnabled },
                                set: { settingsViewModel.isHapticFeedbackEnabled = $0 }
                            )) {
                                HStack(spacing: 12) {
                                    Image(systemName: "hand.tap.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.blue)
                                        .frame(width: 28, height: 28)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                    
                                    Text("Haptic Feedback")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                        }
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal)
                    
                    // General Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("GENERAL")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            settingsViewModel.signOut(authViewModel: authViewModel)
                        }) {
                            HStack {
                                Image(systemName: "person.crop.circle.fill.badge.xmark")
                                    .foregroundColor(.red)
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Settings")
            .background(Color(.systemBackground).ignoresSafeArea())
            .onChange(of: settingsViewModel.isSignedOut) { signedOut, _ in
                if signedOut {
                    authViewModel.isSignedIn = false
                }
            }
            .onAppear {
                settingsViewModel.name = authViewModel.userName
                settingsViewModel.email = authViewModel.userEmail
                settingsViewModel.imageURL = authViewModel.userProfileImageURL
            }
            .sheet(isPresented: $isShareSheetPresented) {
                ShareSheet(activityItems: [
                    "Check out AdRadar - the best way to track your AdSense earnings!",
                    "https://example.com/adradar" // Placeholder URL until App Store submission
                ])
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $isWidgetSupportSheetPresented) {
                VStack(spacing: 20) {
                    Image("LoginScreen")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.top)
                    
                    Text("Widget Support")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Are your widgets not updating frequently or at all?")
                                .font(.headline)
                            
                            Text("Unfortunately Apple does not give developers a hug amount of control over how often a background refresh happens.")
                            
                            Text("The operating system attempts to be intuitive and learns at what points pf the day you use the app, and then does a background refresh just beforehand.")
                            
                            Text("I would suggest using the app for a week or so, then you should start to see the widget update more frequently as the operating system learns how often you like to view the data.")
                            
                            Text("You will need to make sure that notifications are switched on for the app, as the app uses background notifications, but please don't worry - we will not bother you with any alerts.")
                            
                            Text("If the app continues not to update the widget, please feel free to contact me directly using the 'Feedback' option.")
                            
                            Text("Thank's for your support.\nGuilio")
                                .padding(.top, 8)
                        }
                        .padding(.horizontal)
                    }
                    
                    Button(action: {
                        isWidgetSupportSheetPresented = false
                    }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isMailSheetPresented) {
                MailView(
                    subject: "AdRadar: User feedback",
                    messageBody: "Any feeback or questions are more than welcome, please enter your message below:"
                )
            }
            .sheet(isPresented: $isTermsSheetPresented) {
                NavigationView {
                    WebView(url: URL(string: "https://www.notion.so/AdRadar-Terms-Privacy-Policy-21539fba0e268090a327da6296c3c99a?source=copy_link")!)
                        .navigationTitle("Terms & Privacy Policy")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    isTermsSheetPresented = false
                                }
                            }
                        }
                }
            }
        }
    }
}

struct AnimatedSettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding()
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isPressed ? 0.7 : 1.0)
        }
    }
}

// ShareSheet view to present the system share sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentation
    let subject: String
    let messageBody: String
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(subject)
        vc.setMessageBody(messageBody, isHTML: false)
        vc.setToRecipients(["apps@delteqis.co.za"])
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView
        
        init(_ parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.presentation.wrappedValue.dismiss()
        }
    }
}

// For preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthViewModel())
            .environmentObject(SettingsViewModel(authViewModel: AuthViewModel()))
            .preferredColorScheme(.light)
        SettingsView()
            .environmentObject(AuthViewModel())
            .environmentObject(SettingsViewModel(authViewModel: AuthViewModel()))
            .preferredColorScheme(.dark)
    }
} 
