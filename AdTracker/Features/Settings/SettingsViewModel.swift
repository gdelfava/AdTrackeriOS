import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var imageURL: URL? = nil
    @Published var isSignedOut: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchUserInfo()
    }
    
    func fetchUserInfo() {
        // TODO: Replace with real Google API call
        // Placeholder values for now
        self.name = "Guilio Del Fava"
        self.email = "gdelfava@gmail.com"
        self.imageURL = URL(string: "https://www.gravatar.com/avatar/00000000000000000000000000000000?d=mp&f=y")
    }
    
    func signOut() {
        // TODO: Clear user data, tokens, etc.
        self.isSignedOut = true
    }
} 