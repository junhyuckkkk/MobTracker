import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo / Branding
            VStack(spacing: 10) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 60))
                    .foregroundColor(.admobBlue)
                
                Text("dashboard_title")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("app_subtitle")
                    .font(.body)
                    .foregroundColor(.slate400)
            }
            
            Spacer()
            
            // Login Button
            Button(action: {
                authService.signIn()
            }) {
                HStack {
                    Image(systemName: "globe") // Placeholder for Google Logo
                    Text("sign_in_google")
                }
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            // Demo Mode Button (browse with sample data, no account needed)
            Button(action: {
                authService.enterDemoMode()
            }) {
                HStack {
                    Image(systemName: "eye")
                    Text("demo_mode_button")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.slate800)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Text("login_disclaimer")
                .font(.caption)
                .foregroundColor(.slate400)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let errorMessage = authService.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.slate900)
    }
}
