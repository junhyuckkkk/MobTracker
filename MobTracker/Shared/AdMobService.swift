import Foundation
import SwiftUI
import GoogleMobileAds

class AdMobService: NSObject, ObservableObject {
    static let shared = AdMobService()
    
    @Published var isAdLoaded: Bool = false
    @Published var isLoading: Bool = false
    private var rewardedAd: RewardedAd?
    private var pendingCompletion: (() -> Void)?
    
    // Ad Unit IDs - reads from Info.plist in production (set via Secrets.xcconfig)
    #if DEBUG
    let adUnitID = "ca-app-pub-3940256099942544/1712485313"
    let bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    #else
    let adUnitID: String = Bundle.main.object(forInfoDictionaryKey: "ADMOB_REWARDED_ID") as? String ?? ""
    let bannerAdUnitID: String = Bundle.main.object(forInfoDictionaryKey: "ADMOB_BANNER_ID") as? String ?? ""
    #endif
    
    override init() {
        super.init()
        startSDK()
    }
    
    func startSDK() {
        MobileAds.shared.start { [weak self] _ in
            print("AdMob SDK initialized.")
            self?.loadRewardedAd()
        }
    }
    
    // MARK: - Rewarded Ad
    
    func loadRewardedAd() {
        isLoading = true
        let request = Request()
        RewardedAd.load(with: adUnitID, request: request) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Failed to load rewarded ad with error: \(error.localizedDescription)")
                    self?.pendingCompletion = nil
                    return
                }
                
                self?.rewardedAd = ad
                self?.isAdLoaded = true
                print("Rewarded ad loaded.")
                
                // If user was waiting for ad, show it now
                if self?.pendingCompletion != nil {
                    self?.showAdNow()
                }
            }
        }
    }
    
    func showAd(completion: @escaping () -> Void) {
        if rewardedAd != nil {
            pendingCompletion = completion
            showAdNow()
        } else {
            // Save completion and load ad
            print("Ad not ready, loading now...")
            pendingCompletion = completion
            loadRewardedAd()
        }
    }
    
    private func showAdNow() {
        guard let ad = rewardedAd else { return }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            ad.present(from: rootViewController) { [weak self] in
                print("Reward received!")
                self?.pendingCompletion?()
                self?.pendingCompletion = nil
                
                // Reset and reload for next time
                self?.isAdLoaded = false
                self?.rewardedAd = nil
                self?.loadRewardedAd()
            }
        }
    }
}
