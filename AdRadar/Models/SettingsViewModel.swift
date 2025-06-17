import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var imageURL: URL? = nil
    @Published var isSignedOut: Bool = false
    @Published var isHapticFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticFeedbackEnabled, forKey: "isHapticFeedbackEnabled")
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(authViewModel: AuthViewModel) {
        // Initialize isHapticFeedbackEnabled with a default value if not set
        if !UserDefaults.standard.contains(key: "isHapticFeedbackEnabled") {
            UserDefaults.standard.set(true, forKey: "isHapticFeedbackEnabled")
        }
        self.isHapticFeedbackEnabled = UserDefaults.standard.bool(forKey: "isHapticFeedbackEnabled")
        
        authViewModel.$userName.assign(to: &$name)
        authViewModel.$userEmail.assign(to: &$email)
        authViewModel.$userProfileImageURL.assign(to: &$imageURL)
    }
    
    func signOut(authViewModel: AuthViewModel) {
        authViewModel.signOut()
        self.isSignedOut = true
    }
}

extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
} 