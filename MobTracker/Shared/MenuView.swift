import SwiftUI

struct MenuView: View {
    @ObservedObject var authService = AuthService.shared
    @ObservedObject var dataService = DataService.shared
    
    var body: some View {
        ZStack {
            Color.slate900.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("tab_menu")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top)
                    
                    // Account Info (User Profile)
                    if let email = authService.userEmail {
                        HStack(spacing: 16) {
                            // Profile Icon
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.admobBlue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("account_info")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.slate400)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.slate800)
                        .cornerRadius(12)
                    }
                    
                    // Demo Mode Notice
                    if authService.isDemoMode {
                        HStack(spacing: 12) {
                            Image(systemName: "eye")
                                .foregroundColor(.admobBlue)
                            Text("demo_mode_notice")
                                .font(.caption)
                                .foregroundColor(.slate400)
                            Spacer()
                        }
                        .padding()
                        .background(Color.slate800)
                        .cornerRadius(12)
                    }

                    // Logout / Exit Demo
                    Button(action: {
                        authService.signOut()
                    }) {
                        Text(authService.isDemoMode ? LocalizedStringKey("exit_demo_mode") : LocalizedStringKey("logout"))
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.slate800)
                            .cornerRadius(12)
                    }
                    
                    // Copyright
                    Text("© 2025 STATION 44. All rights reserved.")
                        .font(.caption2)
                        .foregroundColor(.slate400)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
                .padding()
            }
        }
    }
}

struct MenuRow: View {
    let icon: String
    let title: LocalizedStringKey
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.slate400)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.slate400)
                .font(.subheadline)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding()
    }
}
