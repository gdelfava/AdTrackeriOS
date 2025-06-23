// App entry point for AdRadar
//
//  AdRadar_App.swift
//  AdRadar
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import SwiftUI
import Combine

@main
struct AdRadar_App: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    init() {
        setupAppEnvironment()
        // Initialize memory monitoring
        setupMemoryMonitoring()
    }
    
    private func setupAppEnvironment() {
        // Configure Sora fonts globally
        configureFonts()
        
        // Initialize core managers in a controlled manner
        initializeManagers()
        
        // Log initialization status
        logInitializationStatus()
    }
    
    private func configureFonts() {
        // Configure navigation and tab bar fonts with Sora
        SoraNavigationAppearance.configure()
        
        // Load and verify Sora fonts
        SoraFontLoader.loadFonts()
    }
    
    private func initializeManagers() {
        // Initialize UserDefaultsManager first (safer)
        _ = UserDefaultsManager.shared
        
        // Initialize MemoryManager with delayed setup
        DispatchQueue.main.async {
            _ = MemoryManager.shared
        }
        
        // Initialize WatchDataSyncService for Apple Watch connectivity
        Task { @MainActor in
            _ = WatchDataSyncService.shared
        }
    }
    
    private func logInitializationStatus() {
        #if DEBUG
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let userDefaultsStatus = UserDefaultsManager.shared.getContainerStatus()
            let memoryInfo = MemoryManager.shared.getMemoryUsageString()
            
            print("""
            [AdRadar] App initialization completed:
            - \(userDefaultsStatus)
            - Initial memory usage: \(memoryInfo)
            - Build configuration: DEBUG
            """)
        }
        #else
        print("[AdRadar] App initialized successfully (Release)")
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenWrapper()
                .environmentObject(authViewModel)
                .environmentObject(NetworkMonitor.shared)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Check memory when app becomes active
                    let memoryPressureDetected = MemoryManager.shared.checkMemoryPressure()
                    if memoryPressureDetected {
                        print("[App] Memory pressure detected on app activation - cleanup performed")
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    // Clean up when app goes to background
                    MemoryManager.shared.performMaintenanceCleanup()
                }
        }
    }
    
    private func setupMemoryMonitoring() {
        #if DEBUG
        // Start periodic memory monitoring in debug builds
        startPeriodicMemoryLogging()
        #endif
    }
    
    #if DEBUG
    private func startPeriodicMemoryLogging() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            let usage = MemoryManager.shared.getCurrentMemoryUsage()
            let usageMB = Double(usage) / (1024 * 1024)
            
            if usageMB > 250 {
                print("⚠️ [MemoryMonitor] High memory usage: \(String(format: "%.1f", usageMB)) MB")
                let cleanupPerformed = MemoryManager.shared.checkMemoryPressure()
                if cleanupPerformed {
                    print("🧹 [MemoryMonitor] Automatic cleanup performed")
                }
            } else {
                print("📊 [MemoryMonitor] Memory usage: \(String(format: "%.1f", usageMB)) MB")
            }
        }
    }
    #endif
}

// MARK: - Splash Screen Wrapper
struct SplashScreenWrapper: View {
    @State private var showSplash = true
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(networkMonitor)
                    .transition(.opacity)
                    .zIndex(0)
            }
        }
        .onReceive(Timer.publish(every: 3.5, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(.easeInOut(duration: 0.8)) {
                showSplash = false
            }
        }
    }
} 