import SwiftUI

struct AppsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: AppViewModel
    @State private var showingDateFilter = false
    @State private var showTotalEarningsCard = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
        _viewModel = StateObject(wrappedValue: AppViewModel(accessToken: nil))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                mainContent
            }
            .navigationTitle("AdMob Apps")
            .toolbar {
                leadingToolbarItem
                trailingToolbarItem
            }
        }
        .sheet(isPresented: $showingDateFilter) {
            DateFilterSheet(selectedFilter: $viewModel.selectedFilter, isPresented: $showingDateFilter) {
                // Reset total earnings card when filter changes
                showTotalEarningsCard = false
                Task {
                    await viewModel.fetchAppData()
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
                Task { await viewModel.fetchAppData() }
            }
            
            // Reset total earnings card visibility
            showTotalEarningsCard = false
        }
        .onChange(of: viewModel.apps) { oldApps, newApps in
            // Show total earnings card after apps have loaded
            if !newApps.isEmpty && viewModel.hasLoaded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showTotalEarningsCard = true
                }
            } else {
                showTotalEarningsCard = false
            }
        }
        .onChange(of: viewModel.hasLoaded) { oldValue, newValue in
            // Reset total earnings card when loading state changes
            if newValue && !viewModel.apps.isEmpty {
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
                ProgressView("Loading apps...")
                    .soraBody()
                    .padding()
                Spacer()
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Error Loading Apps")
                        .soraHeadline()
                        .foregroundColor(.gray)
                    
                    Text(errorMessage)
                        .soraBody()
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        if errorMessage.contains("AdMob access requires additional permissions") {
                            Button("Grant AdMob Permissions") {
                                authViewModel.requestAdditionalScopes()
                            }
                            .soraBody()
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .cornerRadius(8)
                        }
                        
                        Button("Retry") {
                            Task {
                                await viewModel.fetchAppData()
                            }
                        }
                        .soraBody()
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.apps.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "apps.iphone")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    
                    Text("No App Data")
                        .soraHeadline()
                        .foregroundColor(.gray)
                    
                    VStack(spacing: 8) {
                        Text("No AdMob app data available for \(viewModel.selectedFilter.rawValue.lowercased()).")
                            .soraBody()
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Text("Try selecting a different date range or ensure your apps have AdMob ads running.")
                            .soraCaption()
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    Button("Try Different Date Range") {
                        showingDateFilter = true
                    }
                    .soraBody()
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                appsScrollView
            }
        }
    }
    
    private var appsScrollView: some View {
        ScrollView {
            VStack(spacing: 16) {
                totalEarningsCard
                appCardsList
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 100)
        }
        .refreshable {
            if let token = authViewModel.accessToken {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                await viewModel.fetchAppData()
            }
        }
    }
    
    private var totalEarningsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Total Earnings")
                    .soraHeadline()
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(calculateTotalEarnings())
                    .soraLargeTitle()
                    .foregroundColor(.accentColor)
            }
            
            HStack {
                Image(systemName: "apps.iphone")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(viewModel.apps.count) app\(viewModel.apps.count == 1 ? "" : "s")")
                    .soraCaption()
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Period: \(viewModel.selectedFilter.rawValue)")
                    .soraCaption()
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .opacity(showTotalEarningsCard ? 1 : 0)
        .offset(y: showTotalEarningsCard ? 0 : 20)
        .animation(.easeOut(duration: 0.4), value: showTotalEarningsCard)
    }
    
    private var appCardsList: some View {
        LazyVStack(spacing: 16) {
            ForEach(Array(viewModel.apps.enumerated()), id: \.element.id) { index, app in
                AppCard(app: app)
            }
        }
    }
    
    private var leadingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Done") {
                dismiss()
            }
            .soraBody()
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
                    .soraBody()
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
    
    private func calculateTotalEarnings() -> String {
        let totalEarnings = viewModel.apps.reduce(0.0) { sum, app in
            sum + (Double(app.earnings) ?? 0.0)
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current // Use user's locale for currency
        
        return formatter.string(from: NSNumber(value: totalEarnings)) ?? formatter.string(from: NSNumber(value: 0.0)) ?? "0.00"
    }
}

struct AppCard: View {
    let app: AppData
    @State private var isPressed = false
    @State private var showDetailedMetrics = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Section
            headerSection
            
            // Divider
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            // Main Metrics Section
            mainMetricsSection
            
            // Detailed Metrics Section (expandable)
            if showDetailedMetrics {
                detailedMetricsSection
            }
            
            // Expand/Collapse Button
            expandButton
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.3), value: showDetailedMetrics)
        .onTapGesture {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetailedMetrics.toggle()
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // App icon and name
                HStack(spacing: 12) {
                    Image(systemName: "apps.iphone.badge.plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.accentColor)
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.appName)
                            .soraHeadline()
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text("AdMob App Performance")
                            .soraCaption()
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Earnings badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(app.formattedEarnings)
                        .soraTitle2()
                        .foregroundColor(.green)
                    
                    Text("Earnings")
                        .soraCaption2()
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var mainMetricsSection: some View {
        HStack(spacing: 0) {
            MetricPill(
                icon: "eye.fill",
                title: "Impressions",
                value: app.impressions,
                color: .blue
            )
            
            Divider()
                .frame(height: 40)
            
            MetricPill(
                icon: "cursorarrow.click.2",
                title: "Clicks",
                value: app.clicks,
                color: .orange
            )
            
            Divider()
                .frame(height: 40)
            
            MetricPill(
                icon: "percent",
                title: "CTR",
                value: app.formattedCTR,
                color: .purple
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var detailedMetricsSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(.systemGray5))
                .frame(height: 1)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DetailedMetricRow(
                    icon: "doc.text.fill",
                    title: "Requests",
                    value: app.requests,
                    color: .indigo
                )
                
                DetailedMetricRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "RPM",
                    value: app.formattedRPM,
                    color: .pink
                )
                
                DetailedMetricRow(
                    icon: "info.circle.fill",
                    title: "App ID",
                    value: String(app.appId.prefix(20)) + (app.appId.count > 20 ? "..." : ""),
                    color: .teal
                )
                
                DetailedMetricRow(
                    icon: "dollarsign.circle.fill",
                    title: "Revenue",
                    value: app.formattedEarnings,
                    color: .green
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
        }
    }
    
    private var expandButton: some View {
        HStack {
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetailedMetrics.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Text(showDetailedMetrics ? "Less Details" : "More Details")
                        .soraCaption()
                    
                    Image(systemName: showDetailedMetrics ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.accentColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding(.bottom, 16)
    }
}

#Preview {
    AppsView(showSlideOverMenu: .constant(false), selectedTab: .constant(0))
        .environmentObject(AuthViewModel())
} 