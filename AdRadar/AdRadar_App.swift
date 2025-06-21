// App entry point for AdRadar
//
//  AdRadar_App.swift
//  AdRadar
//
//  Created by Guilio Del Fava on 2025/06/12.
//

import SwiftUI

@main
struct AdRadar_App: App {
    init() {
        setupAppEnvironment()
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
            ContentView()
                .applySoraFonts()
                .environmentObject(NetworkMonitor.shared)
                .onAppear {
                    // Perform any additional setup after UI is ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        MemoryManager.shared.performMaintenanceCleanup()
                    }
                }
        }
    }
} 