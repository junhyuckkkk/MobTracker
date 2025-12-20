import Foundation
import GoogleMobileAds
import SwiftUI

class InterstitialAdManager: NSObject, ObservableObject {
    static let shared = InterstitialAdManager()
    
    // Interstitial Ad Unit ID with conditional compilation
    #if DEBUG
    private let adUnitID = "ca-app-pub-3940256099942544/4411468910"  // Test
    #else
    private let adUnitID = "ca-app-pub-9373931451334451/5146511669"  // Real
    #endif
    
    private var interstitialAd: InterstitialAd?
    @Published var isAdReady = false
    
    // Swipe counter
    @Published var swipeCount: Int = 0
    private let firstAdThreshold = 10
    private let subsequentAdInterval = 20
    private var adsShownCount = 0
    
    override init() {
        super.init()
        loadAd()
    }
    
    // MARK: - Load Ad
    
    func loadAd() {
        let request = Request()
        InterstitialAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            if let error = error {
                print("Failed to load interstitial ad: \(error.localizedDescription)")
                self?.isAdReady = false
                return
            }
            self?.interstitialAd = ad
            self?.isAdReady = true
            print("Interstitial ad loaded successfully")
        }
    }
    
    // MARK: - Track Swipe & Show Ad
    
    func trackSwipe() {
        swipeCount += 1
        print("Swipe count: \(swipeCount)")
        
        if shouldShowAd() {
            showAd()
        }
    }
    
    private func shouldShowAd() -> Bool {
        if adsShownCount == 0 {
            // First ad after 10 swipes
            return swipeCount >= firstAdThreshold
        } else {
            // Subsequent ads every 20 swipes after first ad
            let swipesSinceFirstAd = swipeCount - firstAdThreshold
            return swipesSinceFirstAd > 0 && swipesSinceFirstAd % subsequentAdInterval == 0
        }
    }
    
    // MARK: - Show Ad
    
    func showAd() {
        guard let interstitialAd = interstitialAd,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Interstitial ad not ready or no root view controller")
            return
        }
        
        interstitialAd.present(from: rootViewController)
        adsShownCount += 1
        print("Interstitial ad shown. Total ads shown: \(adsShownCount)")
        
        // Reload next ad
        self.interstitialAd = nil
        self.isAdReady = false
        loadAd()
    }
}
