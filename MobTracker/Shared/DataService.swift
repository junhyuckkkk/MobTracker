import Foundation
import WidgetKit

struct EarningData: Codable {
    let today: Double
    let yesterday: Double
    let thisMonth: Double
    let lastMonth: Double
    let thisYear: Double // Modified: Added Annual Data
    let lastYear: Double // Modified: Added Annual Data
    let todayImpressions: Int
    let lastUpdated: Date
}

class DataService: ObservableObject {
    static let shared = DataService()
    
    @Published var currentEarnings: EarningData
    @Published var dailyEarnings: [String: Double] = [:] // Daily earnings map (yyyyMMdd: amount)
    
    private let userDefaults: UserDefaults?
    
    init() {
        // Initialize with App Group
        self.userDefaults = UserDefaults(suiteName: DesignSystem.appGroupIdentifier)
        
        // Load cached data if available, otherwise default to 0.00
        if let cachedData = DataService.getSharedData() {
            self.currentEarnings = cachedData
        } else {
            self.currentEarnings = EarningData(
                today: 0.00,
                yesterday: 0.00,
                thisMonth: 0.00,
                lastMonth: 0.00,
                thisYear: 0.00,
                lastYear: 0.00,
                todayImpressions: 0,
                lastUpdated: Date()
            )
        }
        
        
        // Load cached daily earnings
        if let savedDailyPattern = userDefaults?.dictionary(forKey: "dailyEarnings") as? [String: Double] {
            self.dailyEarnings = savedDailyPattern
        }
        
        refreshData()
    }
    
    func refreshData(completion: (() -> Void)? = nil) {
        // Snapshot Mode: Provide Mock Data
        if CommandLine.arguments.contains("--snapshot") {
            let mockData = EarningData(
                today: 125.50,
                yesterday: 98.20,
                thisMonth: 1250.00,
                lastMonth: 3400.50,
                thisYear: 15400.00,
                lastYear: 45000.00,
                todayImpressions: 1540,
                lastUpdated: Date()
            )
            
            // Generate some mock daily earnings specifically valid for "this month" to populate charts
            // This is a simplified example, populating current month days
            var mockDaily: [String: Double] = [:]
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month], from: Date())
            if let startOfMonth = calendar.date(from: components),
               let range = calendar.range(of: .day, in: .month, for: startOfMonth) {
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd"
                
                for day in 1...min(range.count, 31) { // Populate full month
                   if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                       let key = dateFormatter.string(from: date)
                       mockDaily[key] = Double.random(in: 50...150)
                   }
                }
            }
            
            self.currentEarnings = mockData
            self.dailyEarnings = mockDaily
            self.saveDataToSharedStorage(data: mockData)
            self.saveDailyEarningsToSharedStorage(map: mockDaily)
            WidgetCenter.shared.reloadAllTimelines()
            completion?()
            return
        }
        
        // Check if user is logged in
        guard let publisherId = AuthService.shared.publisherId,
              let accessToken = AuthService.shared.accessToken else {
            print("User not logged in, cannot fetch real data.")
            completion?()
            return
        }
        
        // Fetch from AdMob API
        AdMobAPI.shared.fetchEarnings(publisherId: publisherId, accessToken: accessToken) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (data, dailyMap)):
                    self?.currentEarnings = data
                    self?.dailyEarnings = dailyMap
                    self?.dailyEarnings = dailyMap
                    self?.saveDataToSharedStorage(data: data)
                    self?.saveDailyEarningsToSharedStorage(map: dailyMap)
                    WidgetCenter.shared.reloadAllTimelines()
                case .failure(let error):
                    // Check for 401 Unauthorized
                    if let adMobError = error as? AdMobError, adMobError == .unauthorized {
                        print("Token expired. Refreshing token...")
                        AuthService.shared.refreshToken { success in
                            if success {
                                print("Token refreshed successfully. Retrying data fetch...")
                                // Retry once
                                self?.refreshData(completion: completion)
                            } else {
                                print("Token refresh failed. User needs to login again.")
                                completion?()
                            }
                        }
                        return // Exit here, don't call completion yet
                    }
                    
                    print("Failed to fetch earnings: \(error.localizedDescription)")
                }
                completion?()
            }
        }
    }
    
    private func saveDataToSharedStorage(data: EarningData) {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults?.set(encoded, forKey: "cachedEarnings")
        }
    }
    
    private func saveDailyEarningsToSharedStorage(map: [String: Double]) {
        userDefaults?.set(map, forKey: "dailyEarnings")
    }
    
    // Helper for Widget to read data
    static func getSharedData() -> EarningData? {
        let defaults = UserDefaults(suiteName: DesignSystem.appGroupIdentifier)
        if let data = defaults?.data(forKey: "cachedEarnings") {
            return try? JSONDecoder().decode(EarningData.self, from: data)
        }
        return nil
    }
}
