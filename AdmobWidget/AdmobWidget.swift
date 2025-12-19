import WidgetKit
import SwiftUI
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), earnings: DataService.shared.currentEarnings)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), earnings: DataService.shared.currentEarnings)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        
        // Refresh every 15 minutes to keep data fresh
        let refreshInterval: TimeInterval = 15 * 60
        let refreshDate = Calendar.current.date(byAdding: .second, value: Int(refreshInterval), to: currentDate)!
        
        // Fetch latest data from shared storage
        let earnings = DataService.getSharedData() ?? DataService.shared.currentEarnings
        
        let entry = SimpleEntry(date: currentDate, earnings: earnings)

        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let earnings: EarningData
}

struct RefreshEarningsIntent: AppIntent {
    static var title: LocalizedStringResource = "refresh_earnings"
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        // Always allow refresh
        DispatchQueue.main.async {
            DataService.shared.refreshData()
        }
        
        return .result()
    }
}

struct AdMobWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        let todayRounded = (entry.earnings.today * 100).rounded() / 100
        let yesterdayRounded = (entry.earnings.yesterday * 100).rounded() / 100
        
        ZStack {
            Color.slate900
            
            VStack(alignment: .leading, spacing: 0) {
                // Top Bar (AdMob Colors)
                HStack(spacing: 0) {
                    Color.admobBlue
                    Color.admobRed
                    Color.admobYellow
                    Color.admobGreen
                }
                .frame(height: 4)
                
                // Show Real Data (No Booster Logic)
                VStack(alignment: .leading, spacing: 8) {
                    // Header
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.slate400)
                            .font(.caption)
                        Spacer()
                        
                        // Refresh Button
                        if #available(iOS 17.0, *) {
                            Button(intent: RefreshEarningsIntent()) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Color.slate800)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if family == .systemSmall {
                        Spacer()
                        Text("today_earnings")
                            .font(.caption)
                            .foregroundColor(.slate400)
                        Text(String(format: "$%.2f", entry.earnings.today))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.8)
                        Spacer()
                        
                        // Trend (Calculated)
                        HStack(spacing: 4) {
                            if entry.earnings.yesterday > 0 {
                                if yesterdayRounded > 0 {
                                    let trend = ((todayRounded - yesterdayRounded) / yesterdayRounded) * 100
                                    Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    Text(String(format: "%+.1f%%", trend))
                                } else if todayRounded > 0 {
                                    Image(systemName: "arrow.up.right")
                                    Text("100%+")
                                } else {
                                    Text("-")
                                }
                            }
                        }
                        .font(.caption2)
                        .foregroundColor(
                            (entry.earnings.today >= entry.earnings.yesterday) ? .trendUp : .trendDown
                        )
                        
                    } else {
                        // Medium Widget
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("today_earnings")
                                    .font(.caption)
                                    .foregroundColor(.slate400)
                                Text(String(format: "$%.2f", entry.earnings.today))
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                HStack(spacing: 4) {
                                    if entry.earnings.yesterday > 0 {
                                    
                                    if yesterdayRounded > 0 {
                                        let trend = ((todayRounded - yesterdayRounded) / yesterdayRounded) * 100
                                        Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                        Text(String(format: "%+.1f%%", trend))
                                    } else if todayRounded > 0 {
                                        Image(systemName: "arrow.up.right")
                                        Text("100%+")
                                    } else {
                                        Text("-")
                                    }
                                    }
                                    Text("vs_yesterday")
                                }
                                .font(.caption)
                                .foregroundColor(
                                    (entry.earnings.today >= entry.earnings.yesterday) ? .trendUp : .trendDown
                                )
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 12) {
                                StatRow(title: NSLocalizedString("yesterday", comment: ""), value: entry.earnings.yesterday)
                                StatRow(title: NSLocalizedString("this_month", comment: ""), value: entry.earnings.thisMonth)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: Double
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.slate400)
            Text(String(format: "$%.2f", value))
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
    }
}

@main
struct AdMobWidget: Widget {
    let kind: String = "AdMobWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                AdMobWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                AdMobWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("AdMob Earnings")
        .description("Track your earnings in real-time.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            return containerBackground(color, for: .widget)
        } else {
            return background(color)
        }
    }
}
