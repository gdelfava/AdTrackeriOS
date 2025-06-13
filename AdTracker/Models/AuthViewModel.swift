import Foundation
import GoogleSignIn
import Combine
import Security

class AuthViewModel: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var accessToken: String? = nil
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var userProfileImageURL: URL? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private let keychainService = "com.delteqws.AdTracker"
    private let keychainAccount = "googleAccessToken"
    
    init() {
        // Try to load token from Keychain on init
        if let token = loadTokenFromKeychain() {
            self.accessToken = token
            self.isSignedIn = true
        }
    }
    
    func signIn() {
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            print("No root view controller found")
            return
        }
        let scopes = ["https://www.googleapis.com/auth/adsense.readonly"]
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: scopes) { [weak self] signInResult, error in
            if let error = error {
                print("Google Sign-In error: \(error.localizedDescription)")
                return
            }
            guard let result = signInResult else { return }
            result.user.refreshTokensIfNeeded { auth, error in
                if let error = error {
                    print("Auth error: \(error.localizedDescription)")
                    return
                }
                if let accessToken = auth?.accessToken.tokenString {
                    DispatchQueue.main.async {
                        self?.accessToken = accessToken
                        self?.isSignedIn = true
                        self?.saveTokenToKeychain(accessToken)
                        if let profile = result.user.profile {
                            self?.userName = profile.name
                            self?.userEmail = profile.email
                            self?.userProfileImageURL = profile.hasImage ? profile.imageURL(withDimension: 200) : nil
                        }
                    }
                }
            }
        }
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        accessToken = nil
        isSignedIn = false
        deleteTokenFromKeychain()
        userName = ""
        userEmail = ""
        userProfileImageURL = nil
    }
    
    func refreshTokenIfNeeded() async -> Bool {
        guard let currentUser = GIDSignIn.sharedInstance.currentUser else {
            return false
        }
        
        do {
            let auth = try await currentUser.refreshTokensIfNeeded()
            let newToken = auth.accessToken.tokenString
            
            // Create a local copy of the token to avoid capturing self
            let token = newToken
            
            await MainActor.run {
                self.accessToken = token
                self.saveTokenToKeychain(token)
            }
            return true
        } catch {
            print("Token refresh error: \(error.localizedDescription)")
            // If refresh fails, sign out the user
            await MainActor.run {
                self.signOut()
            }
        }
        return false
    }
    
    // MARK: - Keychain Operations
    
    private func saveTokenToKeychain(_ token: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: token.data(using: .utf8)!
        ]
        
        // First try to delete any existing token
        SecItemDelete(query as CFDictionary)
        
        // Then save the new token
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving token to Keychain: \(status)")
        }
    }
    
    private func loadTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            return token
        }
        return nil
    }
    
    private func deleteTokenFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}