import Foundation
import Combine

struct PaymentsData {
    let unpaidEarnings: String
    let previousPaymentDate: String
    let previousPaymentAmount: String
}

class PaymentsViewModel: ObservableObject {
    @Published var paymentsData: PaymentsData? = nil
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var hasLoaded: Bool = false
    
    var accessToken: String?
    private var accountID: String?
    
    init(accessToken: String?) {
        self.accessToken = accessToken
        if accessToken != nil {
            Task { await fetchPayments() }
        }
    }
    
    @MainActor
    func fetchPayments() async {
        if hasLoaded { return }
        guard let token = accessToken else { return }
        isLoading = true
        error = nil
        // 1. Fetch account ID
        let accountResult = await AdSenseAPI.fetchAccountID(accessToken: token)
        switch accountResult {
        case .success(let accountID):
            self.accountID = accountID
        case .failure(let err):
            self.error = "Failed to get AdSense account: \(err)"
            self.isLoading = false
            return
        }
        guard let accountID = self.accountID else {
            self.error = "No AdSense account found."
            self.isLoading = false
            return
        }
        // 2. Fetch unpaid earnings and previous payment in parallel
        async let unpaidResult = AdSenseAPI.shared.fetchUnpaidEarnings(accessToken: token, accountID: accountID)
        async let prevPaymentResult = AdSenseAPI.shared.fetchPreviousPayment(accessToken: token, accountID: accountID)
        let unpaid = await unpaidResult
        let prev = await prevPaymentResult
        // 3. Format and assign
        func formatCurrency(_ value: Double) -> String {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "ZAR"
            formatter.currencySymbol = "ZAR "
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            return formatter.string(from: NSNumber(value: value)) ?? "ZAR 0.00"
        }
        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "d-M-yyyy"
            return formatter.string(from: date)
        }
        if case .success(let unpaidEarnings) = unpaid {
            switch prev {
            case .success(let prevPayment?):
                // Normal case: payment exists
                let data = PaymentsData(
                    unpaidEarnings: formatCurrency(unpaidEarnings),
                    previousPaymentDate: formatDate(prevPayment.date),
                    previousPaymentAmount: formatCurrency(prevPayment.amount)
                )
                self.paymentsData = data
                self.error = nil
                self.hasLoaded = true
            case .success(nil):
                // No payments yet
                let data = PaymentsData(
                    unpaidEarnings: formatCurrency(unpaidEarnings),
                    previousPaymentDate: "No payments yet",
                    previousPaymentAmount: "-"
                )
                self.paymentsData = data
                self.error = nil
                self.hasLoaded = true
            case .failure(let err):
                self.error = "Failed to load previous payment: \(err)"
            }
        } else {
            self.error = "Failed to load unpaid earnings."
        }
        self.isLoading = false
    }
} 
