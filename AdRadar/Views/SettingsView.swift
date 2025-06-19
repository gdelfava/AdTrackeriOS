import SwiftUI
import MessageUI
import WebKit

// Toast View
struct Toast: View {
    let message: String
    @Binding var isShowing: Bool
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1)
    }
}

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
    @State private var showToast = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            ZStack {
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
                        
                        // Account Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ACCOUNT INFORMATION")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 0) {
                                AccountInfoRow(
                                    title: "Publisher ID",
                                    value: settingsViewModel.publisherId,
                                    isCopyable: true,
                                    onCopy: {
                                        UIPasteboard.general.string = settingsViewModel.publisherId
                                        withAnimation {
                                            showToast = true
                                        }
                                        // Dismiss toast after 2 seconds
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            withAnimation {
                                                showToast = false
                                            }
                                        }
                                    }
                                )
                                Divider()
                                AccountInfoRow(title: "Publisher Name", value: settingsViewModel.publisherName)
                                Divider()
                                AccountInfoRow(title: "Time Zone", value: settingsViewModel.timeZone)
                                Divider()
                                AccountInfoRow(title: "Currency", value: settingsViewModel.currency)
                            }
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        
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
                                AnimatedSettingsRow(icon: "info.circle.fill", color: .blue, title: "Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")") {
                                    // No action needed for version
                                }
                                Divider()
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
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSlideOverMenu = true
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Toast overlay
                if showToast {
                    VStack {
                        Spacer()
                        Toast(message: "Publisher ID copied to clipboard", isShowing: $showToast)
                            .padding(.bottom, 100)
                    }
                }
            }
        }
        .onAppear {
            settingsViewModel.authViewModel = authViewModel
            Task {
                await settingsViewModel.fetchAccountInfo()
            }
        }
        .sheet(isPresented: $isShareSheetPresented) {
            ShareSheet(activityItems: ["Check out AdRadar for AdSense! https://apps.apple.com/app/id1481431267"])
        }
        .sheet(isPresented: $isWidgetSupportSheetPresented) {
            WidgetSupportSheet()
        }
        .sheet(isPresented: $isMailSheetPresented) {
            if MFMailComposeViewController.canSendMail() {
                MailView(toRecipients: ["support@adradar.app"], subject: "AdRadar Feedback", body: "") { result in
                    switch result {
                    case .success:
                        print("Email sent successfully")
                    case .failure(let error):
                        print("Email failed to send: \(error.localizedDescription)")
                    }
                }
            } else {
                // Fallback for devices that can't send email
                Text("Email not available on this device")
                    .padding()
            }
        }
        .sheet(isPresented: $isTermsSheetPresented) {
            TermsAndPrivacySheet()
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
    let toRecipients: [String]
    let subject: String
    let body: String
    let completion: (Result<Void, Error>) -> Void
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(toRecipients)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
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
            if let error = error {
                parent.completion(.failure(error))
            } else {
                parent.completion(.success(()))
            }
            parent.presentation.wrappedValue.dismiss()
        }
    }
}

// For preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(showSlideOverMenu: .constant(false), selectedTab: .constant(0))
            .environmentObject(AuthViewModel())
            .environmentObject(SettingsViewModel(authViewModel: AuthViewModel()))
            .preferredColorScheme(.light)
        SettingsView(showSlideOverMenu: .constant(false), selectedTab: .constant(0))
            .environmentObject(AuthViewModel())
            .environmentObject(SettingsViewModel(authViewModel: AuthViewModel()))
            .preferredColorScheme(.dark)
    }
}

struct AccountInfoRow: View {
    let title: String
    let value: String
    var isCopyable: Bool = false
    var onCopy: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            if isCopyable {
                onCopy?()
            }
        }) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    if isCopyable {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WidgetSupportSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
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
                    
                    Text("Unfortunately Apple does not give developers a huge amount of control over how often a background refresh happens.")
                    
                    Text("The operating system attempts to be intuitive and learns at what points of the day you use the app, and then does a background refresh just beforehand.")
                    
                    Text("I would suggest using the app for a week or so, then you should start to see the widget update more frequently as the operating system learns how often you like to view the data.")
                    
                    Text("You will need to make sure that notifications are switched on for the app, as the app uses background notifications, but please don't worry - we will not bother you with any alerts.")
                    
                    Text("If the app continues not to update the widget, please feel free to contact me directly using the 'Feedback' option.")
                    
                    Text("Thanks for your support.\nGuilio")
                        .padding(.top, 8)
                }
                .padding(.horizontal)
            }
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
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
}

struct TermsAndPrivacySheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            WebView(url: URL(string: "https://www.notion.so/AdRadar-Terms-Privacy-Policy-21539fba0e268090a327da6296c3c99a?source=copy_link")!)
                .navigationTitle("Terms & Privacy Policy")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
        }
    }
} 
