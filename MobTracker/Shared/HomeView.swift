import SwiftUI

struct HomeView: View {
    @ObservedObject var dataService = DataService.shared
    @ObservedObject var adMobService = AdMobService.shared
    
    var body: some View {
        let todayRounded = (dataService.currentEarnings.today * 100).rounded() / 100
        let yesterdayRounded = (dataService.currentEarnings.yesterday * 100).rounded() / 100
        
        ZStack {
            Color.slate900.ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            VStack(alignment: .leading) {
                                Text("dashboard_title")
                                    .font(.headline)
                                    .foregroundColor(.slate400)
                                Text(Date(), style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.slate400.opacity(0.8))
                            }
                            Spacer()
                        }
                        .padding(.top)
                        .id("top") // Mark top for scrolling
                        
                        // Hero Card: Today's Earnings
                        VStack(spacing: 10) {
                            Text("today_earnings")
                                .font(.subheadline)
                                .foregroundColor(.slate400)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(alignment: .lastTextBaseline) {
                                Text("$")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                Text(String(format: "%.2f", dataService.currentEarnings.today))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Trend Line (Calculated)
                            HStack {
                                if yesterdayRounded > 0 {
                                    let trend = ((todayRounded - yesterdayRounded) / yesterdayRounded) * 100
                                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    Text(String(format: "%+.1f%%", trend))
                                    Text("vs_yesterday")
                                } else if todayRounded > 0 {
                                    // Yesterday was 0, but today has earnings
                                    Image(systemName: "arrow.up.right")
                                    Text("100%+")
                                    Text("vs_yesterday")
                                } else {
                                    // Both 0
                                    Text("-")
                                    Text("vs_yesterday")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(
                                (todayRounded >= yesterdayRounded) ? .trendUp : .trendDown
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)
                        .background(Color.slate800)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
                        
                        // Annual Revenue (New)
                        TotalRevenueCard()

                        // All-Time + Last Year Highlights
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            HighlightCard(
                                title: NSLocalizedString("all_time_revenue", comment: ""),
                                icon: "infinity",
                                value: dataService.currentEarnings.allTime,
                                accent: .admobYellow
                            )
                            HighlightCard(
                                title: NSLocalizedString("last_year_performance", comment: ""),
                                icon: "calendar",
                                value: dataService.currentEarnings.lastYear,
                                accent: .admobBlue
                            )
                        }

                        // Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            StatCard(title: NSLocalizedString("yesterday", comment: ""), value: dataService.currentEarnings.yesterday, color: .slate400)
                            StatCard(title: NSLocalizedString("this_month", comment: ""), value: dataService.currentEarnings.thisMonth, color: .admobBlue)
                            StatCard(title: NSLocalizedString("last_month", comment: ""), value: dataService.currentEarnings.lastMonth, color: .white)
                            
                            // eCPM Calculation
                            let ecpm = dataService.currentEarnings.todayImpressions > 0 
                                ? (dataService.currentEarnings.today / Double(dataService.currentEarnings.todayImpressions)) * 1000.0 
                                : 0.0
                            
                            StatCard(title: "eCPM", value: ecpm, color: .admobGreen)
                        }
                        
                        // Banner Ad (hidden during screenshot automation)
                        if !CommandLine.arguments.contains("--snapshot") {
                            BannerAdWidget(adUnitID: AdMobService.shared.bannerAdUnitID)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                        }
                        
                        // Revenue Chart (Current vs Previous Month)
                        RevenueChartView()
                    }
                    .padding()
                }
                .refreshable {
                    await withCheckedContinuation { continuation in
                        dataService.refreshData {
                            continuation.resume()
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ScrollToTop"))) { _ in
                    withAnimation {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
        }
        .onAppear {
            // Auto-refresh when view appears
            dataService.refreshData()
        }
    }
}

// Helper View for Stats
struct StatCard: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.slate400)
            
            Text(String(format: "$%.2f", value))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.slate800)
        .cornerRadius(12)
    }
}

// Highlight Card (All-Time / Last Year)
struct HighlightCard: View {
    let title: String
    let icon: String
    let value: Double
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(accent)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.slate400)
            }

            Text(String(format: "$%.2f", value))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.slate800)
        .cornerRadius(12)
    }
}

// Annual Revenue Card
struct TotalRevenueCard: View {
    @ObservedObject var dataService = DataService.shared
    
    var body: some View {
        let thisYear = dataService.currentEarnings.thisYear
        let lastYear = dataService.currentEarnings.lastYear
        
        let growth: Double = {
            if lastYear > 0 {
                return ((thisYear - lastYear) / lastYear) * 100
            } else if thisYear > 0 {
                return 100.0
            }
            return 0.0
        }()
        
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return HStack(alignment: .center) {
            // Left: Current Year Total
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: NSLocalizedString("total_year", comment: ""), String(currentYear)))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(String(format: "$%.2f", thisYear))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Right: Comparison
            VStack(alignment: .trailing, spacing: 6) {
                // Growth % (Top)
                HStack(spacing: 4) {
                    Image(systemName: growth >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                        .fontWeight(.bold)
                    
                    Text(String(format: "%.1f%%", abs(growth)))
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(growth >= 0 ? .admobGreen : .admobRed)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    (growth >= 0 ? Color.admobGreen : Color.admobRed).opacity(0.1)
                )
                .cornerRadius(6)
                
                // Last Year Total (Bottom)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: NSLocalizedString("total_year", comment: ""), String(currentYear - 1)))
                        .font(.caption2)
                        .foregroundColor(.slate400)
                    Text(String(format: "$%.2f", lastYear))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.slate400)
                }
            }
        }
        .padding(16)
        .background(Color.slate800)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
    }
}
