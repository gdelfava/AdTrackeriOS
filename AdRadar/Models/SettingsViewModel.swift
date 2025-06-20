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
    
    // Payment Threshold
    @Published var paymentThreshold: Double = 100.0
    
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
        
        // Initialize payment threshold - default based on currency
        if let savedThreshold = UserDefaults.standard.object(forKey: "paymentThreshold") as? Double {
            self.paymentThreshold = savedThreshold
        } else {
            // Set default thresholds based on currency
            switch currency {
            case "USD", "EUR", "GBP", "CAD", "AUD":
                self.paymentThreshold = 100.0
            case "ZAR":
                self.paymentThreshold = 1000.0
            case "INR":
                self.paymentThreshold = 8000.0
            case "JPY":
                self.paymentThreshold = 12000.0
            case "BRL":
                self.paymentThreshold = 500.0
            case "MXN":
                self.paymentThreshold = 2000.0
            default:
                self.paymentThreshold = 100.0
            }
            // Save default threshold
            UserDefaults.standard.set(self.paymentThreshold, forKey: "paymentThreshold")
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
    
    func updatePaymentThreshold(_ threshold: Double) {
        self.paymentThreshold = threshold
        UserDefaults.standard.set(threshold, forKey: "paymentThreshold")
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