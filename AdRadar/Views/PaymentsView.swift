import SwiftUI

struct PaymentsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: PaymentsViewModel
    @Environment(\.colorScheme) private var uiColorScheme
    @State private var unpaidCardAppeared = false
    @State private var previousCardAppeared = false
    @State private var imageAppeared = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: PaymentsViewModel(accessToken: nil))
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
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
                            .opacity(unpaidCardAppeared ? 1 : 0)
                            .offset(y: unpaidCardAppeared ? 0 : 20)
                            
                            PreviousPaymentCardView(
                                amount: data.previousPaymentAmount,
                                date: data.previousPaymentDate
                            )
                            .opacity(previousCardAppeared ? 1 : 0)
                            .offset(y: previousCardAppeared ? 0 : 20)
                            
                            Image(uiColorScheme == .dark ? "moneyjumpblk2" : "moneyjumpwht2")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 330)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .opacity(imageAppeared ? 1 : 0)
                                .scaleEffect(imageAppeared ? 1 : 0.8)
                                .onAppear {
                                    // Animate unpaid card first
                                    withAnimation(.easeOut(duration: 0.5)) {
                                        unpaidCardAppeared = true
                                    }
                                    
                                    // Animate previous payment card after delay
                                    withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                                        previousCardAppeared = true
                                    }
                                    
                                    // Animate image after cards
                                    withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                                        imageAppeared = true
                                    }
                                }
                                .onDisappear {
                                    // Reset animation states when view disappears
                                    unpaidCardAppeared = false
                                    previousCardAppeared = false
                                    imageAppeared = false
                                }
                            Spacer()
                        }
                        .padding(.horizontal)
                        Text("AdRadar is not affiliated with Google or Google AdSense. All data is provided by Google and is subject to their terms of service.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.bottom, 20)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSlideOverMenu = true
                        }
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
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
    PaymentsView(showSlideOverMenu: .constant(false), selectedTab: .constant(0))
        .environmentObject(AuthViewModel())
}
