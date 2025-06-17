import Foundation
import GoogleMobileAds
import UserMessagingPlatform

class ConsentManager {
    static let shared = ConsentManager()
    
    private init() {}
    
    func requestConsent(completion: @escaping (Bool) -> Void) {
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false
        
        ConsentInformation.shared.requestConsentInfoUpdate(
            with: parameters
        ) { error in
            if let error = error {
                print("Failed to request consent info update: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            self.loadAndPresentConsentForm(completion: completion)
        }
    }
    
    private func loadAndPresentConsentForm(completion: @escaping (Bool) -> Void) {
        let status = ConsentInformation.shared.consentStatus
        
        switch status {
        case .notRequired:
            print("Consent not required")
            completion(true)
        case .obtained:
            print("Consent already obtained")
            completion(true)
        case .required:
            ConsentForm.load { form, error in
                if let error = error {
                    print("Failed to load consent form: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let form = form else {
                    print("Consent form is nil")
                    completion(false)
                    return
                }
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    form.present(from: rootViewController) { error in
                        if let error = error {
                            print("Failed to present consent form: \(error.localizedDescription)")
                            completion(false)
                            return
                        }
                        
                        // Check the consent status after the form is dismissed
                        let newStatus = ConsentInformation.shared.consentStatus
                        completion(newStatus == .obtained)
                    }
                } else {
                    print("Could not get root view controller")
                    completion(false)
                }
            }
        case .unknown:
            print("Consent status unknown")
            completion(false)
        @unknown default:
            print("Unknown consent status")
            completion(false)
        }
    }
} 
