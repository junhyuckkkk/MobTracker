//
//  ContentView.swift
//  admob tracker
//
//  Created by 권준혁 on 12/1/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var authService = AuthService.shared
    @State private var selection = 0
    
    // Haptic Feedback
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        Group {
            if authService.isAuthenticated {
                ZStack(alignment: .bottom) {
                    // Main Content
                    TabView(selection: $selection) {
                        HomeView()
                            .tag(0)
                        
                        CalendarView()
                            .tag(1)
                        
                        MenuView()
                            .tag(2)
                    }
                    
                    // Custom Tab Bar
                    HStack(spacing: 0) {
                        // Home Tab
                        TabBarButton(
                            imageName: "house.fill",
                            title: "tab_home",
                            isSelected: selection == 0
                        ) {
                            if selection == 0 {
                                // Refresh behavior
                                print("Home tab tapped again, refreshing...")
                                DataService.shared.refreshData()
                                NotificationCenter.default.post(name: Notification.Name("ScrollToTop"), object: nil)
                            }
                            selection = 0
                            haptic.impactOccurred()
                        }
                        
                        // Calendar Tab
                        TabBarButton(
                            imageName: "calendar",
                            title: "tab_calendar",
                            isSelected: selection == 1
                        ) {
                            if selection == 1 {
                                // Reset behavior
                                print("Calendar tab tapped again, resetting...")
                                NotificationCenter.default.post(name: Notification.Name("ResetCalendar"), object: nil)
                            }
                            selection = 1
                            haptic.impactOccurred()
                        }
                        
                        // Menu Tab
                        TabBarButton(
                            imageName: "line.3.horizontal",
                            title: "tab_menu",
                            isSelected: selection == 2
                        ) {
                            selection = 2
                            haptic.impactOccurred()
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 34) // Safe Area
                    .background(Color.slate800)
                    .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: -5)
                    .edgesIgnoringSafeArea(.bottom)
                }
                .onAppear {
                    // Hide Native Tab Bar
                    UITabBar.appearance().isHidden = true
                }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authService.isAuthenticated)
        .onChange(of: authService.isAuthenticated) { newValue in
            if newValue {
                selection = 0
            }
        }
    }
}

// Custom Tab Bar Button
struct TabBarButton: View {
    let imageName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: imageName)
                    .font(.system(size: 24))
                Text(NSLocalizedString(title, comment: ""))
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
            }
            .foregroundColor(isSelected ? .admobBlue : .slate400)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

// Helper for Rounded Corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}



#Preview {
    ContentView()
}

