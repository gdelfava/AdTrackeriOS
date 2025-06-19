import SwiftUI

struct PlatformView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: PlatformViewModel
    @State private var showingDateFilter = false
    @State private var showTotalEarningsCard = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
        _viewModel = StateObject(wrappedValue: PlatformViewModel(accessToken: nil))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                mainContent
            }
            .navigationTitle("Platforms")
            .toolbar {
                leadingToolbarItem
                trailingToolbarItem
            }
        }
        .sheet(isPresented: $showingDateFilter) {
            PlatformDateFilterSheet(selectedFilter: $viewModel.selectedFilter, isPresented: $showingDateFilter) {
                // Reset total earnings card when filter changes
                showTotalEarningsCard = false
                Task {
                    await viewModel.fetchPlatformData()
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
                Task { await viewModel.fetchPlatformData() }
            }
            
            // Reset total earnings card visibility
            showTotalEarningsCard = false
        }
        .onChange(of: viewModel.platforms) { oldPlatforms, newPlatforms in
            // Show total earnings card after platforms have loaded
            if !newPlatforms.isEmpty && viewModel.hasLoaded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTotalEarningsCard = true
                }
            } else {
                showTotalEarningsCard = false
            }
        }
        .onChange(of: viewModel.hasLoaded) { oldValue, newValue in
            // Reset total earnings card when loading state changes
            if newValue && !viewModel.platforms.isEmpty {
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
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading platforms...")
                    .padding()
                Spacer()
            } else if viewModel.platforms.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "display.2")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No Platform Data")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("No platform data available for the selected time period.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                platformsScrollView
            }
        }
    }
    
    private var platformsScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                totalEarningsCard
                platformCardsList
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 100)
        }
        .refreshable {
            if let token = authViewModel.accessToken {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                await viewModel.fetchPlatformData()
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
    
    private var platformCardsList: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(viewModel.platforms.enumerated()), id: \.element.id) { index, platform in
                PlatformCard(platform: platform)
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
    
    // MARK: - Helper Methods
    
    private func calculateTotalEarnings() -> String {
        let total = viewModel.platforms.reduce(0.0) { sum, platform in
            sum + (Double(platform.earnings) ?? 0.0)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: total)) ?? "0.00"
    }
    
    private func errorSymbol(for error: String) -> String {
        if error.contains("network") || error.contains("connection") {
            return "wifi.slash"
        } else if error.contains("unauthorized") || error.contains("token") {
            return "lock.slash"
        } else {
            return "exclamationmark.triangle"
        }
    }
}

struct PlatformDateFilterSheet: View {
    @Binding var selectedFilter: PlatformDateFilter
    @Binding var isPresented: Bool
    var onFilterSelected: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(PlatformDateFilter.allCases, id: \.self) { filter in
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

#Preview {
    PlatformView(showSlideOverMenu: .constant(false), selectedTab: .constant(0))
        .environmentObject(AuthViewModel())
} 