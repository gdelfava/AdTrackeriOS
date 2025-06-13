import SwiftUI

struct PaymentsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: PaymentsViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: PaymentsViewModel(accessToken: nil))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading...")
                        .padding()
                    Spacer()
                } else if let error = viewModel.error {
                    Spacer()
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                    Spacer()
                } else if let data = viewModel.paymentsData {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payments")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 16)
                        PaymentCardView(
                            title: "Unpaid Earnings",
                            value: data.unpaidEarnings
                        )
                        PaymentCardView(
                            title: "Previous Payment Date: \(data.previousPaymentDate)",
                            value: data.previousPaymentAmount
                        )
                    }
                    .padding(.horizontal)
                    Spacer()
                    Text("AdTracker is not affiliated with Google, Google AdSense or Google AdMob")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                } else {
                    Spacer()
                }
            }
            .background(Color(.systemBackground))
            .onAppear {
                if let token = authViewModel.accessToken {
                    viewModel.accessToken = token
                    Task { await viewModel.fetchPayments() }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct PaymentCardView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.largeTitle)
                .bold()
                .foregroundColor(.primary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    PaymentsView()
        .environmentObject(AuthViewModel())
} 
