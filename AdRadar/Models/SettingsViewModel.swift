import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var imageURL: URL? = nil
    @Published var isSignedOut: Bool = false
    
    // Account Information
    @Published var publisherId: String = ""
    @Published var publisherName: String = ""
    @Published var timeZone: String = ""
    @Published var currency: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        
        authViewModel.$userName.assign(to: &$name)
        authViewModel.$userEmail.assign(to: &$email)
        authViewModel.$userProfileImageURL.assign(to: &$imageURL)
        
        // Initialize account information from UserDefaults
        self.publisherId = UserDefaults.standard.string(forKey: "publisherId") ?? ""
        self.publisherName = UserDefaults.standard.string(forKey: "publisherName") ?? ""
        self.timeZone = UserDefaults.standard.string(forKey: "timeZone") ?? Foundation.TimeZone.current.identifier
        
        // Get currency from UserDefaults or use the user's locale currency
        if let savedCurrency = UserDefaults.standard.string(forKey: "currency") {
            self.currency = savedCurrency
        } else {
            // Get the currency code from the user's locale
            let locale = Locale.current
            if let currencyCode = locale.currency?.identifier {
                self.currency = currencyCode
                // Save it to UserDefaults for future use
                UserDefaults.standard.set(currencyCode, forKey: "currency")
            } else {
                // Fallback to ZAR if currency code can't be determined
                self.currency = "ZAR"
            }
        }
        
        // Fetch account information when initialized
        Task {
            await fetchAccountInfo()
        }
    }
    
    func signOut(authViewModel: AuthViewModel) {
        authViewModel.signOut()
        self.isSignedOut = true
    }
    
    @MainActor
    func fetchAccountInfo() async {
        guard let accessToken = authViewModel.accessToken else { return }
        
        switch await AdSenseAPI.shared.fetchAccountInfo(accessToken: accessToken) {
        case .success(let account):
            // Extract publisher ID from account name (format: accounts/pub-XXXXXXXX)
            if let publisherId = account.name.split(separator: "/").last {
                self.publisherId = String(publisherId)
                UserDefaults.standard.set(self.publisherId, forKey: "publisherId")
            }
            
            self.publisherName = account.displayName
            UserDefaults.standard.set(self.publisherName, forKey: "publisherName")
            
            if let timeZone = account.timeZone?.id {
                self.timeZone = timeZone
                UserDefaults.standard.set(self.timeZone, forKey: "timeZone")
            }
            
        case .failure(let error):
            print("Failed to fetch account info: \(error)")
        }
    }
}

extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
} 