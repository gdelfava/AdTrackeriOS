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
    private let keychainService = "com.delteqws.AdRadar"
    private let keychainAccount = "googleAccessToken"
    private let userNameKey = "userName"
    private let userEmailKey = "userEmail"
    private let userProfileImageURLKey = "userProfileImageURL"
    
    init() {
        // Load cached values synchronously (these are fast local operations)
        if let token = loadTokenFromKeychain() {
            self.accessToken = token
            self.isSignedIn = true
        }
        
        // Load user info from UserDefaults
        let defaults = UserDefaults.standard
        self.userName = defaults.string(forKey: userNameKey) ?? ""
        self.userEmail = defaults.string(forKey: userEmailKey) ?? ""
        if let urlString = defaults.string(forKey: userProfileImageURLKey), let url = URL(string: urlString) {
            self.userProfileImageURL = url
        }
        
        // Defer Google Sign-In restoration to async method to prevent blocking init
        Task {
            await restoreGoogleSignInSession()
        }
    }
    
    /// Restores Google Sign-In session asynchronously to avoid blocking main thread during init
    private func restoreGoogleSignInSession() async {
        await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                if let user = user, error == nil {
                    user.refreshTokensIfNeeded { auth, error in
                        if let accessToken = auth?.accessToken.tokenString {
                            Task { @MainActor in
                                self.accessToken = accessToken
                                self.isSignedIn = true
                                self.saveTokenToKeychain(accessToken)
                                if let profile = user.profile {
                                    self.userName = profile.name
                                    self.userEmail = profile.email
                                    self.userProfileImageURL = profile.hasImage ? profile.imageURL(withDimension: 200) : nil
                                    // Save to UserDefaults
                                    let defaults = UserDefaults.standard
                                    defaults.set(profile.name, forKey: self.userNameKey)
                                    defaults.set(profile.email, forKey: self.userEmailKey)
                                    if let url = self.userProfileImageURL?.absoluteString {
                                        defaults.set(url, forKey: self.userProfileImageURLKey)
                                    } else {
                                        defaults.removeObject(forKey: self.userProfileImageURLKey)
                                    }
                                }
                                continuation.resume()
                            }
                        } else {
                            continuation.resume()
                        }
                    }
                } else {
                    continuation.resume()
                }
            }
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
        let scopes = ["https://www.googleapis.com/auth/adsense.readonly", "https://www.googleapis.com/auth/admob.readonly"]
        print("Requesting scopes: \(scopes)")
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
                        print("Sign-in successful. Granted scopes: \(result.user.grantedScopes ?? [])")
                        if let profile = result.user.profile {
                            self?.userName = profile.name
                            self?.userEmail = profile.email
                            self?.userProfileImageURL = profile.hasImage ? profile.imageURL(withDimension: 200) : nil
                            // Save to UserDefaults
                            let defaults = UserDefaults.standard
                            defaults.set(profile.name, forKey: self?.userNameKey ?? "userName")
                            defaults.set(profile.email, forKey: self?.userEmailKey ?? "userEmail")
                            if let url = self?.userProfileImageURL?.absoluteString {
                                defaults.set(url, forKey: self?.userProfileImageURLKey ?? "userProfileImageURL")
                            } else {
                                defaults.removeObject(forKey: self?.userProfileImageURLKey ?? "userProfileImageURL")
                            }
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
        // Remove from UserDefaults
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: userNameKey)
        defaults.removeObject(forKey: userEmailKey)
        defaults.removeObject(forKey: userProfileImageURLKey)
        // Clear AdSense account ID
        UserDefaultsManager.shared.removeValue(forKey: "adSenseAccountID")
    }
    
    func requestAdditionalScopes() {
        guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {
            print("No root view controller found")
            return
        }
        
        // Sign out first to force fresh authentication with new scopes
        GIDSignIn.sharedInstance.signOut()
        
        // Use the full scopes list including the new AdMob scope
        let allScopes = ["https://www.googleapis.com/auth/adsense.readonly", "https://www.googleapis.com/auth/admob.readonly"]
        
        // Configure Google Sign-In with the scopes
        if let configuration = GIDSignIn.sharedInstance.configuration {
            let newConfig = GIDConfiguration(clientID: configuration.clientID)
            GIDSignIn.sharedInstance.configuration = newConfig
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: allScopes) { [weak self] signInResult, error in
            if let error = error {
                print("Error requesting additional scopes: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    // If sign-in fails, restore signed-out state
                    self?.accessToken = nil
                    self?.isSignedIn = false
                    self?.deleteTokenFromKeychain()
                }
                return
            }
            
            guard let result = signInResult else { return }
            
            result.user.refreshTokensIfNeeded { auth, error in
                if let error = error {
                    print("Auth error after scope addition: \(error.localizedDescription)")
                    return
                }
                
                if let accessToken = auth?.accessToken.tokenString {
                    DispatchQueue.main.async {
                        self?.accessToken = accessToken
                        self?.isSignedIn = true
                        self?.saveTokenToKeychain(accessToken)
                        
                        // Update user info
                        if let profile = result.user.profile {
                            self?.userName = profile.name
                            self?.userEmail = profile.email
                            self?.userProfileImageURL = profile.hasImage ? profile.imageURL(withDimension: 200) : nil
                            
                            // Save to UserDefaults
                            let defaults = UserDefaults.standard
                            defaults.set(profile.name, forKey: self?.userNameKey ?? "userName")
                            defaults.set(profile.email, forKey: self?.userEmailKey ?? "userEmail")
                            if let url = self?.userProfileImageURL?.absoluteString {
                                defaults.set(url, forKey: self?.userProfileImageURLKey ?? "userProfileImageURL")
                            }
                        }
                        
                        print("Successfully requested additional scopes and updated token")
                        print("Granted scopes: \(result.user.grantedScopes ?? [])")
                    }
                }
            }
        }
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