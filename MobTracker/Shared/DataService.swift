import Foundation
import WidgetKit

struct EarningData: Codable {
    let today: Double
    let yesterday: Double
    let thisMonth: Double
    let lastMonth: Double
    let thisYear: Double // Modified: Added Annual Data
    let lastYear: Double // Modified: Added Annual Data
    let allTime: Double
    let todayImpressions: Int
    let lastUpdated: Date

    init(
        today: Double,
        yesterday: Double,
        thisMonth: Double,
        lastMonth: Double,
        thisYear: Double,
        lastYear: Double,
        allTime: Double,
        todayImpressions: Int,
        lastUpdated: Date
    ) {
        self.today = today
        self.yesterday = yesterday
        self.thisMonth = thisMonth
        self.lastMonth = lastMonth
        self.thisYear = thisYear
        self.lastYear = lastYear
        self.allTime = allTime
        self.todayImpressions = todayImpressions
        self.lastUpdated = lastUpdated
    }

    // Decode with backward compatibility for cached data missing `allTime`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.today = try container.decode(Double.self, forKey: .today)
        self.yesterday = try container.decode(Double.self, forKey: .yesterday)
        self.thisMonth = try container.decode(Double.self, forKey: .thisMonth)
        self.lastMonth = try container.decode(Double.self, forKey: .lastMonth)
        self.thisYear = try container.decode(Double.self, forKey: .thisYear)
        self.lastYear = try container.decode(Double.self, forKey: .lastYear)
        self.allTime = try container.decodeIfPresent(Double.self, forKey: .allTime) ?? 0.0
        self.todayImpressions = try container.decode(Int.self, forKey: .todayImpressions)
        self.lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
    }
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
                allTime: 0.00,
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
        // Demo/Snapshot Mode: Provide Mock Data (App Store review, screenshots)
        if CommandLine.arguments.contains("--snapshot") || AuthService.shared.isDemoMode {
            loadDemoData(completion: completion)
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
    
    // Sample earnings for demo mode. Values are derived from the date string,
    // so they stay stable across refreshes/relaunches and the app, calendar,
    // and widget all agree.
    private func loadDemoData(completion: (() -> Void)?) {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let today = calendar.startOfDay(for: Date())

        // Cover the past ~2 years so the calendar can be browsed back through last year
        var mockDaily: [String: Double] = [:]
        for offset in 0..<800 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = dateFormatter.string(from: date)
            let seed = key.unicodeScalars.reduce(0) { $0 + Int($1.value) }
            mockDaily[key] = Double(40 + (seed * 7) % 120) + 0.5
        }

        func sum(from start: Date, to end: Date) -> Double {
            var total = 0.0
            var date = start
            while date <= end {
                total += mockDaily[dateFormatter.string(from: date)] ?? 0
                guard let next = calendar.date(byAdding: .day, value: 1, to: date) else { break }
                date = next
            }
            return total
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
        let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? today
        let endOfLastMonth = calendar.date(byAdding: .day, value: -1, to: startOfMonth) ?? today
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: today)) ?? today
        let startOfLastYear = calendar.date(byAdding: .year, value: -1, to: startOfYear) ?? today
        let endOfLastYear = calendar.date(byAdding: .day, value: -1, to: startOfYear) ?? today

        let todayValue = mockDaily[dateFormatter.string(from: today)] ?? 0
        let thisYear = sum(from: startOfYear, to: today)
        let lastYear = sum(from: startOfLastYear, to: endOfLastYear)

        let mockData = EarningData(
            today: todayValue,
            yesterday: mockDaily[dateFormatter.string(from: yesterday)] ?? 0,
            thisMonth: sum(from: startOfMonth, to: today),
            lastMonth: sum(from: startOfLastMonth, to: endOfLastMonth),
            thisYear: thisYear,
            lastYear: lastYear,
            allTime: thisYear + lastYear + 41234.56,
            todayImpressions: Int(todayValue * 12),
            lastUpdated: Date()
        )

        self.currentEarnings = mockData
        self.dailyEarnings = mockDaily
        self.saveDataToSharedStorage(data: mockData)
        self.saveDailyEarningsToSharedStorage(map: mockDaily)
        WidgetCenter.shared.reloadAllTimelines()
        completion?()
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
