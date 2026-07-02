//
//  ContentView.swift
//  admob tracker
//
//  Created by 권준혁 on 12/1/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var authService = AuthService.shared
    
    // Custom Tab Bar Appearance
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.slate800)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    @State private var selection = 0
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                // Custom Binding for Tab Selection
                let binding = Binding<Int>(
                    get: { self.selection },
                    set: { newValue in
                        // Haptic Feedback for any tab tap
                        HapticManager.instance.impact(style: .light)
                        
                        if newValue == self.selection {
                            if newValue == 0 {
                                // Tapped Home again -> Refresh & Scroll to Top
                                print("Home tab tapped again, refreshing and scrolling up...")
                                DataService.shared.refreshData()
                                NotificationCenter.default.post(name: Notification.Name("ScrollToTop"), object: nil)
                            } else if newValue == 1 {
                                // Tapped Calendar again -> Reset to Today
                                print("Calendar tab tapped again, resetting...")
                                NotificationCenter.default.post(name: Notification.Name("ResetCalendar"), object: nil)
                            }
                        }
                        self.selection = newValue
                    }
                )
                
                TabView(selection: binding) {
                    HomeView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("tab_home")
                        }
                        .tag(0)
                    
                    CalendarView()
                        .tabItem {
                            Image(systemName: "calendar")
                            Text("tab_calendar")
                        }
                        .tag(1)
                    
                    MenuView()
                        .tabItem {
                            Image(systemName: "line.3.horizontal")
                            Text("tab_menu")
                        }
                        .tag(2)
                }
                .accentColor(.admobBlue)
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
        .onChange(of: authService.isAuthenticated) { isAuth in
            if isAuth {
                selection = 0
            }
        }
    }
}



#Preview {
    ContentView()
}

