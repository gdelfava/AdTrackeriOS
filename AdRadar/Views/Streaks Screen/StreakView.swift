import SwiftUI
import Charts
import UIKit

struct StreakView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: StreakViewModel
    @State private var selectedDay: StreakDayData?
    @State private var calendarAppeared = false
    @State private var overviewAppeared = false
    @State private var detailsAppeared = false
    @State private var animateFloatingElements = false
    @Binding var showSlideOverMenu: Bool
    @Binding var selectedTab: Int
    
    init(showSlideOverMenu: Binding<Bool>, selectedTab: Binding<Int>) {
        _viewModel = StateObject(wrappedValue: StreakViewModel(accessToken: nil))
        _showSlideOverMenu = showSlideOverMenu
        _selectedTab = selectedTab
    }
    
    // Auto-select current day if available, otherwise first day
    private var displayDay: StreakDayData? {
        selectedDay ?? currentDay ?? viewModel.streakData.first
    }
    
    // Find today's date in the data
    private var currentDay: StreakDayData? {
        let today = Date()
        return viewModel.streakData.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background - always full screen
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color.accentColor.opacity(0.1),
                        Color(.systemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea(.all)
                
                // Floating elements for visual interest
                StreakFloatingElementsView(animate: $animateFloatingElements)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Last Updated Header
                        if !viewModel.isLoading && !viewModel.streakData.isEmpty {
                            StreakHeaderView(lastUpdateTime: viewModel.lastUpdateTime)
                                .padding(.horizontal, 20)
                        }
                        
                        if viewModel.isLoading {
                            Spacer()
                            ProgressView("Loading...")
                                .soraBody()
                                .padding()
                            Spacer()
                        } else if viewModel.showEmptyState {
                            Spacer()
                            StreakEmptyStateView(message: viewModel.emptyStateMessage ?? "")
                            Spacer()
                        } else {
                            // Compact Horizontal Date Picker
                            HorizontalDatePickerView(
                                selectedDay: $selectedDay,
                                streakData: viewModel.streakData
                            )
                            .opacity(calendarAppeared ? 1 : 0)
                            .offset(y: calendarAppeared ? 0 : 20)
                            .padding(.horizontal, 20)
                            
                            // Selected Day Detailed Metrics
                            if let displayDay = displayDay {
                                SelectedDayMetricsView(
                                    day: displayDay,
                                    viewModel: viewModel,
                                    showCloseButton: false
                                )
                                .opacity(detailsAppeared ? 1 : 0)
                                .offset(y: detailsAppeared ? 0 : 20)
                                .padding(.horizontal, 20)
                            }
                            
                            // 7-Day Overview Cards
                            OverviewCardsView(streakData: viewModel.streakData, viewModel: viewModel)
                                .opacity(overviewAppeared ? 1 : 0)
                                .offset(y: overviewAppeared ? 0 : 20)
                                .padding(.horizontal, 20)
                            
                            // Performance Insights
                            PerformanceInsightsView(streakData: viewModel.streakData, viewModel: viewModel)
                                .opacity(overviewAppeared ? 1 : 0)
                                .offset(y: overviewAppeared ? 0 : 20)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .refreshable {
                if let token = authViewModel.accessToken {
                    viewModel.accessToken = token
                    viewModel.authViewModel = authViewModel
                    // Reset selected day to allow auto-selection of current day after refresh
                    selectedDay = nil
                    await viewModel.fetchStreakData()
                }
            }
            .navigationTitle("Streak")
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
        .onAppear {
            // Only fetch data on first load, not on every tab switch
            if let token = authViewModel.accessToken, !viewModel.hasLoaded {
                viewModel.accessToken = token
                viewModel.authViewModel = authViewModel
                Task { await viewModel.fetchStreakData() }
            }
            
            // Staggered animations
            withAnimation(.easeOut(duration: 0.5)) {
                calendarAppeared = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                overviewAppeared = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                detailsAppeared = true
            }
            
            // Animate floating elements
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateFloatingElements = true
            }
        }
        .onChange(of: viewModel.streakData) { _, newData in
            // Auto-select current day when data loads, fallback to first day
            if selectedDay == nil && !newData.isEmpty {
                let today = Date()
                selectedDay = newData.first { Calendar.current.isDate($0.date, inSameDayAs: today) } ?? newData.first
            }
        }
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
} 