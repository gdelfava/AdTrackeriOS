import SwiftUI

struct PaymentsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: PaymentsViewModel
    @Environment(\.colorScheme) private var uiColorScheme
    
    init() {
        _viewModel = StateObject(wrappedValue: PaymentsViewModel(accessToken: nil))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 22) {
                    if viewModel.isLoading {
                        Spacer()
                        ProgressView("Loading...")
                            .padding()
                        Spacer()
                    } else if let error = viewModel.error {
                        Spacer()
                        ErrorBannerView(message: error, symbol: errorSymbol(for: error))
                        Spacer()
                    } else if let data = viewModel.paymentsData {
                        VStack(alignment: .leading, spacing: 12) {
                            UnpaidEarningsCardView(
                                amount: data.unpaidEarnings,
                                date: data.previousPaymentDate,
                                isPaid: false // Set logic as needed
                            )
                            PreviousPaymentCardView(
                                amount: data.previousPaymentAmount,
                                date: data.previousPaymentDate
                            )
                            
                            Image(uiColorScheme == .dark ? "moneyjumpblk2" : "moneyjumpwht2")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        .padding(.horizontal)
                        Text("AdsenseTracker is not affiliated with Google or Google AdSense. All data is provided by Google and is subject to their terms of service.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                    } else {
                    }
                }
                .padding(.top)
            }
            .background(Color(.systemBackground))
            .onAppear {
                if let token = authViewModel.accessToken, !viewModel.hasLoaded {
                    viewModel.accessToken = token
                    Task { await viewModel.fetchPayments() }
                }
            }
            .navigationTitle("Payments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileImageView(url: authViewModel.userProfileImageURL)
                        .contextMenu {
                            Button(role: .destructive) {
                                authViewModel.signOut()
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                }
            }
        }
    }
    
    // Helper to pick an SF Symbol for the error
    private func errorSymbol(for error: String) -> String {
        if error.localizedCaseInsensitiveContains("internet") || error.localizedCaseInsensitiveContains("offline") {
            return "wifi.slash"
        } else if error.localizedCaseInsensitiveContains("unauthorized") || error.localizedCaseInsensitiveContains("session") {
            return "person.crop.circle.badge.exclamationmark"
        } else {
            return "exclamationmark.triangle"
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
                .font(.system(size: 34, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

struct UnpaidEarningsCardView: View {
    let amount: String
    let date: String
    let isPaid: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                        //.padding(2)
                        //.background(Color(.systemGray3))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Text("Unpaid Earnings")
                        .font(.caption2.weight(.regular))
                        .foregroundColor(.primary)
                    Spacer()
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(amount)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .fontDesign(.rounded)
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text("Pending")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Status pill
            HStack {
                Text(isPaid ? "Paid" : "Unpaid")
                    .font(.caption.weight(.medium))
                    .foregroundColor(isPaid ? .white : .red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isPaid ? Color.green : Color.red.opacity(0.18))
                    .clipShape(Capsule())
            }
            .padding(18)
        }
        //.frame(height: 110)
        .padding(.horizontal, 2)
    }
}

struct PreviousPaymentCardView: View {
    let amount: String
    let date: String
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.systemGray6))
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center) {
                    Text("Previous Payment")
                        .font(.caption2.weight(.regular))
                        .foregroundColor(.primary)
                    Spacer()
                }
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(amount)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .fontDesign(.rounded)
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                Text(date)
                    .font(.caption2)
                    .foregroundColor(Color.primary.opacity(0.7))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Status pill
            HStack {
                Text("Paid")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.18))
                    .clipShape(Capsule())
            }
            .padding(18)
        }
        //.frame(height: 110)
        .padding(.horizontal, 2)
    }
}

#Preview {
    PaymentsView()
        .environmentObject(AuthViewModel())
}
