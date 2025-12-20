import Foundation
import GoogleMobileAds
import SwiftUI

class AppOpenAdManager: NSObject, ObservableObject {
    static let shared = AppOpenAdManager()
    
    // Test Ad Unit ID (replace with real one for production)
    private let adUnitID = "ca-app-pub-3940256099942544/5575463023"
    
    private var appOpenAd: GADAppOpenAd?
    @Published var isAdReady = false
    @Published var isShowingAd = false
    
    // Frequency control
    private var lastAdShowTime: Date?
    private let minimumInterval: TimeInterval = 60 * 60 // 1 hour
    private var dailyAdCount: Int = 0
    private var lastAdDate: Date?
    private let maxDailyAds = 3
    
    override init() {
        super.init()
        loadAd()
    }
    
    // MARK: - Load Ad
    
    func loadAd() {
        let request = GADRequest()
        GADAppOpenAd.load(
            withAdUnitID: adUnitID,
            request: request
        ) { [weak self] ad, error in
            if let error = error {
                print("Failed to load App Open ad: \(error.localizedDescription)")
                self?.isAdReady = false
                return
            }
            self?.appOpenAd = ad
            self?.isAdReady = true
            print("App Open ad loaded successfully")
        }
    }
    
    // MARK: - Show Ad (with conditions)
    
    func showAdIfAvailable() {
        // Check if user is logged in
        guard AuthService.shared.isLoggedIn else {
            print("App Open Ad: User not logged in, skipping")
            return
        }
        
        // Check if ad is ready
        guard isAdReady, let appOpenAd = appOpenAd else {
            print("App Open Ad: Ad not ready")
            loadAd()
            return
        }
        
        // Check minimum interval (1 hour)
        if let lastTime = lastAdShowTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < minimumInterval {
                print("App Open Ad: Too soon since last ad (\(Int(elapsed))s < \(Int(minimumInterval))s)")
                return
            }
        }
        
        // Check daily limit
        resetDailyCountIfNeeded()
        if dailyAdCount >= maxDailyAds {
            print("App Open Ad: Daily limit reached (\(dailyAdCount)/\(maxDailyAds))")
            return
        }
        
        // Show ad
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("App Open Ad: No root view controller")
            return
        }
        
        isShowingAd = true
        appOpenAd.present(fromRootViewController: rootViewController)
        
        // Update counters
        lastAdShowTime = Date()
        dailyAdCount += 1
        lastAdDate = Date()
        print("App Open Ad shown. Daily count: \(dailyAdCount)/\(maxDailyAds)")
        
        // Reload next ad
        self.appOpenAd = nil
        self.isAdReady = false
        isShowingAd = false
        loadAd()
    }
    
    // MARK: - Helpers
    
    private func resetDailyCountIfNeeded() {
        guard let lastDate = lastAdDate else { return }
        
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastDate) {
            dailyAdCount = 0
            print("App Open Ad: Daily count reset")
        }
    }
}
