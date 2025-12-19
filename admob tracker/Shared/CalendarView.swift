import SwiftUI

struct CalendarView: View {
    @ObservedObject var dataService = DataService.shared
    
    // Paging State
    @State private var currentPageIndex: Int = 0
    
    // Picker State
    @State private var showYearPicker = false
    @State private var showMonthPicker = false
    
    // Base Date (2020-01-01)
    private let baseDate: Date = {
        var components = DateComponents()
        components.year = 2020 
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components)!
    }()
    
    var body: some View {
        ZStack {
            Color.slate900.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("tab_calendar")
                        .font(.headline)
                        .foregroundColor(.slate400)
                    Spacer()
                    
                    // Button to jump to today
                    Button(action: {
                        withAnimation {
                            jumpToToday()
                        }
                    }) {
                        Text("today")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.slate800)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Month Navigator with Pickers
                HStack(spacing: 20) {
                    Button(action: {
                        withAnimation {
                            currentPageIndex -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding(8)
                    }
                    
                    HStack(spacing: 4) {
                        // Year Picker Button
                        Button(action: { showYearPicker = true }) {
                            Text(yearString(for: currentMonth))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .sheet(isPresented: $showYearPicker) {
                            YearPickerSheet(currentYear: currentYearInt(for: currentMonth)) { selectedYear in
                                jumpTo(year: selectedYear, month: currentMonthInt(for: currentMonth))
                            }
                            .presentationDetents([.height(300)])
                        }
                        
                        // Month Picker Button
                        Button(action: { showMonthPicker = true }) {
                            Text(monthString(for: currentMonth))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .sheet(isPresented: $showMonthPicker) {
                            MonthPickerSheet(currentMonth: currentMonthInt(for: currentMonth)) { selectedMonth in
                                jumpTo(year: currentYearInt(for: currentMonth), month: selectedMonth)
                            }
                            .presentationDetents([.height(400)])
                        }
                    }
                    .frame(minWidth: 140)
                    
                    Button(action: {
                        withAnimation {
                            currentPageIndex += 1
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white)
                            .padding(8)
                    }
                }
                .padding(.vertical, 16)
                
                // Monthly Total
                VStack(spacing: 4) {
                    Text(String(format: "$%.2f", monthlyTotal(for: currentMonth)))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.admobGreen)
                    Text("monthly_total")
                        .font(.caption)
                        .foregroundColor(.slate400)
                }
                .padding(.bottom, 20)
                
                // Weekday Headers
                HStack(spacing: 0) {
                    ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                        Text(day)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.slate400)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
                
                // Paging Calendar Grid
                TabView(selection: $currentPageIndex) {
                    // Range: 0 to 300 (25 years from 2020)
                    ForEach(0..<300, id: \.self) { index in
                        CalendarGridView(month: dateForIndex(index), dataService: dataService)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Banner Ad at Bottom
                BannerAdWidget(adUnitID: AdMobService.shared.bannerAdUnitID)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Spacer()
            }
        }
        .onAppear {
            jumpToToday()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ResetCalendar"))) { _ in
            withAnimation {
                jumpToToday()
            }
        }
    }
    
    // MARK: - Navigation Logic
    
    private var currentMonth: Date {
        return dateForIndex(currentPageIndex)
    }
    
    private func dateForIndex(_ index: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: index, to: baseDate) ?? baseDate
    }
    
    private func jumpToToday() {
        let components = Calendar.current.dateComponents([.month], from: baseDate, to: Date())
        if let monthDiff = components.month {
            currentPageIndex = monthDiff
        }
    }
    
    private func jumpTo(year: Int, month: Int) {
        // Calculate new index
        let targetComponents = DateComponents(year: year, month: month, day: 1)
        if let targetDate = Calendar.current.date(from: targetComponents) {
            let diffComponents = Calendar.current.dateComponents([.month], from: baseDate, to: targetDate)
            if let monthDiff = diffComponents.month {
                withAnimation {
                    currentPageIndex = monthDiff
                }
            }
        }
    }
    
    // MARK: - Formatters & Helpers
    
    private func yearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년"
        return formatter.string(from: date)
    }
    
    private func monthString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월"
        return formatter.string(from: date)
    }
    
    private func currentYearInt(for date: Date) -> Int {
        return Calendar.current.component(.year, from: date)
    }
    
    private func currentMonthInt(for date: Date) -> Int {
        return Calendar.current.component(.month, from: date)
    }
    
    private func monthlyTotal(for date: Date) -> Double {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        
        let components = calendar.dateComponents([.year, .month], from: date)
        var total = 0.0
        
        for (dateStr, amount) in dataService.dailyEarnings {
            if let d = dateFormatter.date(from: dateStr) {
                let dComponents = calendar.dateComponents([.year, .month], from: d)
                if dComponents.year == components.year && dComponents.month == components.month {
                    total += amount
                }
            }
        }
        return total
    }
}

// MARK: - Subviews

struct YearPickerSheet: View {
    let currentYear: Int
    let onSelect: (Int) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    let years = Array(2020...2030)
    
    var body: some View {
        ZStack {
            Color.slate900.ignoresSafeArea()
            
            VStack {
                Text("select_year")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Picker("Year", selection: Binding(
                    get: { currentYear },
                    set: { newYear in
                        onSelect(newYear)
                        presentationMode.wrappedValue.dismiss()
                    }
                )) {
                    ForEach(years, id: \.self) { year in
                        Text(String(format: "%d년", year))
                            .foregroundColor(.white)
                            .tag(year)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                .colorScheme(.dark)
            }
        }
    }
}

struct MonthPickerSheet: View {
    let currentMonth: Int
    let onSelect: (Int) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    let months = Array(1...12)
    
    var body: some View {
        ZStack {
            Color.slate900.ignoresSafeArea()
            
            VStack {
                Text("select_month")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(months, id: \.self) { month in
                        Button(action: {
                            onSelect(month)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("\(month)월")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(month == currentMonth ? .white : .slate400)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(month == currentMonth ? Color.admobBlue : Color.slate800)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
}

// Subview for Grid Performance (Unchanged)
struct CalendarGridView: View {
    let month: Date
    @ObservedObject var dataService: DataService
    
    private let calendar = Calendar.current
    
    var body: some View {
        VStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 0) {
                ForEach(daysInMonth, id: \.self) { day in
                    if let day = day {
                        VStack(spacing: 2) {
                            Text("\(day)")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            let earnings = earningsFor(day: day)
                            if earnings > 0 {
                                Text(String(format: "+$%.2f", earnings))
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.admobGreen)
                            } else {
                                Text("-")
                                    .font(.system(size: 11))
                                    .foregroundColor(.slate400.opacity(0.5))
                            }
                        }
                        .frame(height: 50)
                    } else {
                        // Empty cell
                        VStack {
                            Text("")
                        }
                        .frame(height: 50)
                    }
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
        }
    }
    
    private var daysInMonth: [Int?] {
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let firstDayOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        var days: [Int?] = Array(repeating: nil, count: firstWeekday - 1)
        days += range.map { Optional($0) }
        
        return days
    }
    
    private func earningsFor(day: Int) -> Double {
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let year = components.year, let month = components.month else { return 0 }
        
        let dateStr = String(format: "%04d%02d%02d", year, month, day)
        return dataService.dailyEarnings[dateStr] ?? 0
    }
}
