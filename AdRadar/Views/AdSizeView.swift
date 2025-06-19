import SwiftUI

struct AdSizeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: AdSizeViewModel
    @State private var showingDateFilter = false
    @State private var showTotalEarningsCard = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
        _viewModel = StateObject(wrappedValue: AdSizeViewModel(accessToken: nil))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                mainContent
            }
            .navigationTitle("Ad Sizes")
            .toolbar {
                leadingToolbarItem
                trailingToolbarItem
            }
        }
        .sheet(isPresented: $showingDateFilter) {
            AdSizeDateFilterSheet(selectedFilter: $viewModel.selectedFilter, isPresented: $showingDateFilter) {
                // Reset total earnings card when filter changes
                showTotalEarningsCard = false
                Task {
                    await viewModel.fetchAdSizeData()
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            filterButton
        }
        .onAppear {
            if let token = authViewModel.accessToken, !viewModel.hasLoaded {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                Task { await viewModel.fetchAdSizeData() }
            }
            
            // Reset total earnings card visibility
            showTotalEarningsCard = false
        }
        .onChange(of: viewModel.adSizes) { oldAdSizes, newAdSizes in
            // Show total earnings card after ad sizes have loaded
            if !newAdSizes.isEmpty && viewModel.hasLoaded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTotalEarningsCard = true
                }
            } else {
                showTotalEarningsCard = false
            }
        }
        .onChange(of: viewModel.hasLoaded) { oldValue, newValue in
            // Reset total earnings card when loading state changes
            if newValue && !viewModel.adSizes.isEmpty {
                showTotalEarningsCard = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showTotalEarningsCard = true
                }
            } else {
                showTotalEarningsCard = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var mainContent: some View {
        Group {
            if let error = viewModel.error {
                ErrorBannerView(message: error, symbol: errorSymbol(for: error))
                    .padding(.horizontal)
                    .padding(.top)
            }
            
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading ad sizes...")
                    .padding()
                Spacer()
            } else if viewModel.adSizes.isEmpty && viewModel.hasLoaded {
                emptyStateView
            } else {
                adSizesScrollView
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.3.group")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Ad Size Data")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("No ad size data available for the selected time period.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var adSizesScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                totalEarningsCard
                adSizeCardsList
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 100)
        }
        .refreshable {
            if let token = authViewModel.accessToken {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                await viewModel.fetchAdSizeData()
            }
        }
    }
    
    private var totalEarningsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Total Earnings")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(calculateTotalEarnings())
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(showTotalEarningsCard ? 1 : 0)
        .offset(y: showTotalEarningsCard ? 0 : 20)
        .animation(.easeOut(duration: 0.4), value: showTotalEarningsCard)
    }
    
    private var adSizeCardsList: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(viewModel.adSizes.enumerated()), id: \.element.id) { index, adSize in
                AdSizeCard(adSize: adSize)
            }
        }
    }
    
    private var leadingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Done") {
                dismiss()
            }
            .foregroundColor(.accentColor)
        }
    }
    
    private var trailingToolbarItem: some ToolbarContent {
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
    
    private var filterButton: some View {
        Button(action: {
            showingDateFilter = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.body)
                    .foregroundColor(.white)
                Text(viewModel.selectedFilter.rawValue)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    private func errorSymbol(for error: String) -> String {
        if error.localizedCaseInsensitiveContains("internet") || error.localizedCaseInsensitiveContains("offline") {
            return "wifi.slash"
        } else if error.localizedCaseInsensitiveContains("unauthorized") || error.localizedCaseInsensitiveContains("session") {
            return "person.crop.circle.badge.exclamationmark"
        } else {
            return "exclamationmark.triangle"
        }
    }
    
    private func calculateTotalEarnings() -> String {
        let totalEarnings = viewModel.adSizes.reduce(0.0) { sum, adSize in
            sum + (Double(adSize.earnings) ?? 0.0)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current // Use user's locale for currency
        
        return formatter.string(from: NSNumber(value: totalEarnings)) ?? formatter.string(from: NSNumber(value: 0.0)) ?? "0.00"
    }
}

struct AdSizeDateFilterSheet: View {
    @Binding var selectedFilter: AdSizeDateFilter
    @Binding var isPresented: Bool
    var onFilterSelected: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(AdSizeDateFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        selectedFilter = filter
                        onFilterSelected()
                        isPresented = false
                    }) {
                        HStack {
                            Text(filter.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedFilter == filter {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Date Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.height(350)])
    }
} 