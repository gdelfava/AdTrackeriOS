import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var imageURL: URL? = nil
    @Published var isSignedOut: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init(authViewModel: AuthViewModel) {
        authViewModel.$userName.assign(to: &$name)
        authViewModel.$userEmail.assign(to: &$email)
        authViewModel.$userProfileImageURL.assign(to: &$imageURL)
    }
    
    func signOut(authViewModel: AuthViewModel) {
        authViewModel.signOut()
        self.isSignedOut = true
    }
} 