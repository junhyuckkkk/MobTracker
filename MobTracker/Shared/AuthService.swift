import Foundation
import SwiftUI
import AuthenticationServices

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated: Bool = false
    @Published var userEmail: String?
    @Published var accessToken: String?
    @Published var publisherId: String? // Will be fetched or manually entered
    @Published var errorMessage: String? // For UI feedback
    
    private let userDefaults = UserDefaults(suiteName: DesignSystem.appGroupIdentifier)
    
    // Configuration - reads from Info.plist (set via Secrets.xcconfig)
    private let clientID: String = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String ?? ""
    private let additionalScopes = ["https://www.googleapis.com/auth/admob.readonly"]
    
    init() {
        if CommandLine.arguments.contains("--snapshot") {
            setupSnapshotState()
        } else {
            restoreSession()
        }
    }
    
    private func setupSnapshotState() {
        print("📸 Snapshot mode detected! Skipping login...")
        self.isAuthenticated = true
        self.userEmail = "demo@example.com"
        self.accessToken = "mock_token_for_snapshot"
        self.publisherId = "pub-3940256099942544"
        
        // Mock data initialization if needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            DataService.shared.refreshData()
        }
    }
    
    func restoreSession() {
        // Try to restore from GIDSignIn if available
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            if let user = user {
                self?.updateUser(user: user)
            } else {
                self?.restoreFromDefaults()
            }
        }
        #else
        restoreFromDefaults()
        #endif
    }
    
    private func restoreFromDefaults() {
        if let token = userDefaults?.string(forKey: "mock_access_token") {
            self.accessToken = token
            self.isAuthenticated = true
            self.userEmail = userDefaults?.string(forKey: "mock_user_email")
            self.publisherId = userDefaults?.string(forKey: "mock_publisher_id")
        }
    }
    
    @available(iOSApplicationExtension, unavailable)
    func signIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            self.errorMessage = "Root View Controller not found."
            return
        }
        
        #if canImport(GoogleSignIn)
        // Configure
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Sign In
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController, hint: nil, additionalScopes: additionalScopes) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = "Login failed: \(error.localizedDescription)"
                return
            }
            
            guard let user = result?.user else { return }
            self?.updateUser(user: user)
        }
        #else
        self.errorMessage = "GoogleSignIn SDK is missing. Please install the package in Xcode."
        #endif
    }
    
    func signOut() {
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
        #endif
        
        self.isAuthenticated = false
        self.accessToken = nil
        self.userEmail = nil
        
        userDefaults?.removeObject(forKey: "mock_access_token")
        userDefaults?.removeObject(forKey: "mock_user_email")
        // We might want to keep publisher ID or force re-fetch
    }
    
    #if canImport(GoogleSignIn)
    private func updateUser(user: GIDGoogleUser) {
        self.userEmail = user.profile?.email
        self.accessToken = user.accessToken.tokenString
        self.isAuthenticated = true
        
        // Save to Shared Defaults for Widget
        self.userDefaults?.set(self.accessToken, forKey: "mock_access_token")
        self.userDefaults?.set(self.userEmail, forKey: "mock_user_email")
        
        // Note: Publisher ID is NOT automatically available from Google Sign-In.
        // We need to fetch it from AdMob API or ask user.
        // For now, we'll try to fetch it if we have a token.
        if let token = self.accessToken {
            fetchPublisherId(token: token)
        }
    }
    #endif
    
    private func fetchPublisherId(token: String) {
        // In a real scenario, we list accounts: https://admob.googleapis.com/v1/accounts
        // For now, we will use the test ID if not found, or try to fetch.
        // Let's assume we trigger a fetch in AdMobAPI
        AdMobAPI.shared.fetchPublisherId(accessToken: token) { [weak self] id in
            DispatchQueue.main.async {
                if let id = id {
                    self?.publisherId = id
                    self?.userDefaults?.set(id, forKey: "mock_publisher_id")
                } else {
                    // Fallback for demo
                    let demoId = "pub-3940256099942544"
                    self?.publisherId = demoId
                    self?.userDefaults?.set(demoId, forKey: "mock_publisher_id")
                }
                
                // Trigger initial data fetch AFTER publisher ID is set
                print("Publisher ID set, refreshing data...")
                DataService.shared.refreshData()
            }
        }
    }
    func refreshToken(completion: @escaping (Bool) -> Void) {
        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
            if let user = user {
                self?.updateUser(user: user)
                completion(true)
            } else {
                completion(false)
            }
        }
        #else
        completion(false)
        #endif
    }
}
