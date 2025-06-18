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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(NetworkMonitor.shared)
        }
    }
} 