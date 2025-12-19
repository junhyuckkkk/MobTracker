import Foundation

enum AdMobError: Error, Equatable {
    case unauthorized
    case invalidResponse
    case apiError(String)
}

class AdMobAPI {
    static let shared = AdMobAPI()
    
    private let baseURL = "https://admob.googleapis.com/v1"
    
    // Helper to fetch Publisher ID (Account Name)
    func fetchPublisherId(accessToken: String, completion: @escaping (String?) -> Void) {
        let urlString = "\(baseURL)/accounts"
        guard let url = URL(string: urlString) else { completion(nil); return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching accounts: \(error?.localizedDescription ?? "Unknown")")
                completion(nil)
                return
            }
            
            // Response format: { "account": [ { "name": "accounts/pub-xxxxxxxx", ... } ] }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let accounts = json["account"] as? [[String: Any]],
               let firstAccount = accounts.first,
               let name = firstAccount["name"] as? String {
                // Extract "pub-xxxxxxxx" from "accounts/pub-xxxxxxxx"
                let components = name.components(separatedBy: "/")
                if components.count > 1 {
                    completion(components[1])
                } else {
                    completion(name)
                }
            } else {
                completion(nil)
            }
        }.resume()
    }
    
    // Fetches earnings for a specific date range
    func fetchEarnings(publisherId: String, accessToken: String, completion: @escaping (Result<(EarningData, [String: Double]), Error>) -> Void) {
        let urlString = "\(baseURL)/accounts/\(publisherId)/networkReport:generate"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Calculate Date Range (Last 10 years to cover all history)
        let calendar = Calendar.current
        let today = Date()
        // Fetch roughly 10 years of data
        guard let startDate = calendar.date(byAdding: .day, value: -3650, to: today) else { return }
        
        let startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: today)
        
        let body: [String: Any] = [
            "reportSpec": [
                "dateRange": [
                    "startDate": [
                        "year": startComponents.year,
                        "month": startComponents.month,
                        "day": startComponents.day
                    ],
                    "endDate": [
                        "year": endComponents.year,
                        "month": endComponents.month,
                        "day": endComponents.day
                    ]
                ],
                "metrics": ["ESTIMATED_EARNINGS", "IMPRESSIONS"],
                "dimensions": ["DATE"]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        print("Fetching real AdMob data for \(publisherId)...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    print("AdMob API returned 401 Unauthorized")
                    completion(.failure(AdMobError.unauthorized))
                    return
                }
            }
            
            guard let data = data else { return }
            
            // Debug: Print response
            if let str = String(data: data, encoding: .utf8) {
                print("--- AdMob API Raw Response ---")
                print(str)
                print("------------------------------")
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    var earningsMap: [String: Double] = [:]
                    var impressionsMap: [String: Int] = [:]
                    
                    for item in jsonArray {
                        if let row = item["row"] as? [String: Any],
                           let dimensionValues = row["dimensionValues"] as? [String: [String: Any]],
                           let dateValue = dimensionValues["DATE"]?["value"] as? String,
                           let metricValues = row["metricValues"] as? [String: [String: Any]] {
                            
                            // Earnings
                            if let earningsMicrosStr = metricValues["ESTIMATED_EARNINGS"]?["microsValue"] as? String,
                               let micros = Double(earningsMicrosStr) {
                                earningsMap[dateValue] = micros / 1_000_000.0
                            }
                            
                            // Impressions
                            if let impressionsStr = metricValues["IMPRESSIONS"]?["integerValue"] as? String,
                               let impressions = Int(impressionsStr) {
                                impressionsMap[dateValue] = impressions
                            }
                        }
                    }
                    
                    // Aggregate Data
                    let processedData = self.processEarnings(earningsMap: earningsMap, impressionsMap: impressionsMap)
                    DispatchQueue.main.async {
                        completion(.success((processedData, earningsMap)))
                    }
                } else {
                    // Try to parse as error
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let error = json["error"] as? [String: Any],
                       let message = error["message"] as? String {
                        print("AdMob API Error: \(message)")
                        completion(.failure(NSError(domain: "AdMobAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: message])))
                    } else {
                        print("Failed to parse AdMob response format.")
                        completion(.failure(NSError(domain: "AdMobAPI", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                    }
                }
            } catch {
                print("JSON Parse Error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func processEarnings(earningsMap: [String: Double], impressionsMap: [String: Int]) -> EarningData {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        let todayStr = dateFormatter.string(from: today)
        let yesterdayStr = dateFormatter.string(from: yesterday)
        
        let todayEarnings = earningsMap[todayStr] ?? 0.0
        let yesterdayEarnings = earningsMap[yesterdayStr] ?? 0.0
        let todayImpressions = impressionsMap[todayStr] ?? 0
        
        // This Month
        let currentComponents = calendar.dateComponents([.year, .month], from: today)
        var thisMonthEarnings = 0.0
        
        // Last Month
        let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: today)!
        let lastMonthComponents = calendar.dateComponents([.year, .month], from: lastMonthDate)
        var lastMonthEarnings = 0.0
        
        // Annual Data Calculation
        var thisYearEarnings = 0.0
        var lastYearEarnings = 0.0
        let lastYearInt = (currentComponents.year ?? 2024) - 1
        
        for (dateStr, amount) in earningsMap {
            if let date = dateFormatter.date(from: dateStr) {
                let components = calendar.dateComponents([.year, .month], from: date)
                
                // Monthly logic
                if components.year == currentComponents.year && components.month == currentComponents.month {
                    thisMonthEarnings += amount
                } else if components.year == lastMonthComponents.year && components.month == lastMonthComponents.month {
                    lastMonthEarnings += amount
                }
                
                // Yearly logic
                if components.year == currentComponents.year {
                    thisYearEarnings += amount
                } else if components.year == lastYearInt {
                    lastYearEarnings += amount
                }
            }
        }
        
        return EarningData(
            today: todayEarnings,
            yesterday: yesterdayEarnings,
            thisMonth: thisMonthEarnings,
            lastMonth: lastMonthEarnings,
            thisYear: thisYearEarnings,
            lastYear: lastYearEarnings,
            todayImpressions: todayImpressions,
            lastUpdated: Date()
        )
    }
}
