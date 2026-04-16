//
//  admob_trackerApp.swift
//  admob tracker
//
//  Created by 권준혁 on 12/1/25.
//

import SwiftUI
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@main
struct admob_trackerApp: App {
    // Initialize services when app starts
    init() {
        // Request notification permission
        NotificationService.shared.requestPermission { granted in
            if granted {
                print("Notifications enabled")
            }
        }
    }
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    #if canImport(GoogleSignIn)
                    GIDSignIn.sharedInstance.handle(url)
                    #endif
                }
                .onChange(of: scenePhase) {
                    if scenePhase == .active {
                        print("App became active, refreshing data...")
                        DataService.shared.refreshData()
                    }
                }
        }
    }
}
