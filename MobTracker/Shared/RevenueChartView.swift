import SwiftUI
import Charts

struct RevenueChartView: View {
    @ObservedObject var dataService = DataService.shared
    
    @State private var selectedDay: Int? = nil
    @State private var isLongPressing = false
    @State private var touchLocation: CGPoint = .zero
    @State private var longPressStartTime: Date? = nil
    
    private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text("weekly_comparison")
                .font(.headline)
                .foregroundColor(.white)
            
            // Chart
            chartView
                .frame(height: 180)
            
            // Legend
            HStack(spacing: 20) {
                LegendItem(color: .gray, label: "지난주")
                LegendItem(color: .red, label: "이번주")
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(20)
        .background(Color.slate800)
        .cornerRadius(16)
    }
    
    // MARK: - Chart View
    
    private var chartView: some View {
        Chart {
            // Previous Week Line (Gray)
            ForEach(previousWeekData) { item in
                LineMark(
                    x: .value("Day", item.dayIndex),
                    y: .value("Revenue", item.amount),
                    series: .value("Week", "Previous")
                )
                .foregroundStyle(Color.gray)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.linear)
            }
            
            // Current Week Line (RED)
            ForEach(currentWeekData) { item in
                LineMark(
                    x: .value("Day", item.dayIndex),
                    y: .value("Revenue", item.amount),
                    series: .value("Week", "Current")
                )
                .foregroundStyle(Color.red)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.linear)
            }
            
            // Current Position Dot
            if let lastValidPoint = currentWeekData.last(where: { $0.amount > 0 }) {
                PointMark(
                    x: .value("Day", lastValidPoint.dayIndex),
                    y: .value("Revenue", lastValidPoint.amount)
                )
                .foregroundStyle(Color.red)
                .symbolSize(80)
            }
            
            // Selection Indicator Line
            if isLongPressing, let day = selectedDay {
                RuleMark(x: .value("Day", day))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
            }
        }
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: Array(1...7)) { value in
                AxisValueLabel {
                    if let idx = value.as(Int.self), idx >= 1, idx <= 7 {
                        Text(weekdayLabels[idx - 1])
                            .font(.caption2)
                            .foregroundColor(.slate400)
                            .offset(x: -8)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.slate400.opacity(0.3))
                AxisValueLabel {
                    if let val = value.as(Double.self) {
                        Text(formatCurrency(val))
                            .font(.caption2)
                            .foregroundColor(.slate400)
                    }
                }
            }
        }
        .chartXScale(domain: 0.5...7.5)
        .chartYScale(domain: 0...(maxYValue * 1.2))
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                touchLocation = value.location
                                // Always update selection position
                                updateSelection(at: value.location, proxy: proxy, geo: geo)
                                
                                // Start long press timer if not already pressing
                                if !isLongPressing && longPressStartTime == nil {
                                    longPressStartTime = Date()
                                }
                                
                                // Check if long press threshold reached
                                if let startTime = longPressStartTime,
                                   Date().timeIntervalSince(startTime) >= 0.2 {
                                    if !isLongPressing {
                                        isLongPressing = true
                                        // Haptic on activation
                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                        generator.impactOccurred()
                                    }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.easeOut(duration: 0.2)) {
                                    isLongPressing = false
                                    selectedDay = nil
                                    longPressStartTime = nil
                                }
                            }
                    )
                    .overlay {
                        // Tooltip that follows the touch position
                        if isLongPressing, let day = selectedDay {
                            tooltipView(for: day)
                                .position(x: tooltipXPosition(for: day, proxy: proxy, geo: geo),
                                          y: 30)
                        }
                    }
            }
        }
    }
    
    // MARK: - Tooltip View
    
    private func tooltipView(for day: Int) -> some View {
        let currentAmount = currentWeekData.first(where: { $0.dayIndex == day })?.amount ?? 0
        let prevAmount = previousWeekData.first(where: { $0.dayIndex == day })?.amount ?? 0
        let weekdayName = weekdayLabels[day - 1] + "요일"
        
        return VStack(spacing: 6) {
            // Title: Weekday
            Text(weekdayName)
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Amounts
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 6, height: 6)
                    Text(String(format: "$%.2f", currentAmount))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.gray).frame(width: 6, height: 6)
                    Text(String(format: "$%.2f", prevAmount))
                        .font(.caption2)
                        .foregroundColor(.slate400)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.slate900.opacity(0.95))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 4)
    }
    
    // MARK: - Helper Methods
    
    private func tooltipXPosition(for day: Int, proxy: ChartProxy, geo: GeometryProxy) -> CGFloat {
        // Get X position for the selected day
        if let xPos: CGFloat = proxy.position(forX: day) {
            // Clamp to keep tooltip within bounds
            let tooltipWidth: CGFloat = 140
            let minX = tooltipWidth / 2 + 10
            let maxX = geo.size.width - tooltipWidth / 2 - 10
            return min(max(xPos, minX), maxX)
        }
        return geo.size.width / 2
    }
    
    private func updateSelection(at location: CGPoint, proxy: ChartProxy, geo: GeometryProxy) {
        if let dayValue: Double = proxy.value(atX: location.x) {
            let rounded = Int(round(dayValue))
            let clamped = min(max(rounded, 1), 7)
            if selectedDay != clamped {
                selectedDay = clamped
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
    
    // MARK: - Data Processing
    
    private var currentWeekData: [ChartDataPoint] {
        let allData = weeklyData(for: currentWeekDates)
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date()) // 1 (Sun) ... 7 (Sat)
        
        // Only show data up to today (inclusive)
        var filtered = allData.filter { $0.dayIndex <= todayWeekday }
        
        // Visual Fix: If today's earnings are 0, don't drop the line to zero (unless it's the only point)
        if filtered.count > 1, let last = filtered.last, last.amount == 0 {
            filtered = filtered.dropLast()
        }
        
        return filtered
    }
    
    private var previousWeekData: [ChartDataPoint] {
        return weeklyData(for: previousWeekDates)
    }
    
    private func weeklyData(for dates: [Date]) -> [ChartDataPoint] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        var points: [ChartDataPoint] = []
        
        for (index, date) in dates.enumerated() {
            let dateStr = dateFormatter.string(from: date)
            let dailyAmount = dataService.dailyEarnings[dateStr] ?? 0
            points.append(ChartDataPoint(dayIndex: index + 1, amount: dailyAmount))
        }
        
        return points
    }
    
    private var currentWeekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }
    
    private var previousWeekDates: [Date] {
        let calendar = Calendar.current
        return currentWeekDates.compactMap { calendar.date(byAdding: .day, value: -7, to: $0) }
    }
    
    private var maxYValue: Double {
        let currentMax = currentWeekData.map { $0.amount }.max() ?? 0
        let previousMax = previousWeekData.map { $0.amount }.max() ?? 0
        return max(currentMax, previousMax, 0.01)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        if value >= 1 {
            return String(format: "$%.0f", value)
        } else if value > 0 {
            return String(format: "$%.2f", value)
        } else {
            return "$0"
        }
    }
}

// MARK: - Supporting Types

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let dayIndex: Int
    let amount: Double
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 16, height: 4)
            Text(label)
                .font(.caption)
                .foregroundColor(.slate400)
        }
    }
}
