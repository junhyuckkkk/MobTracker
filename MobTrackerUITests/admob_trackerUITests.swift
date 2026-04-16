//
//  admob_trackerUITests.swift
//  admob trackerUITests
//
//  Created by 권준혁 on 12/1/25.
//

import XCTest

@MainActor
class admob_trackerUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTakeScreenshots() {
        let app = XCUIApplication()
        
        // 1. Dashboard Top
        snapshot("01_Dashboard_Top")
        
        // 2. Dashboard Chart (Scroll down if needed, but standard view shows chart)
        // Let's scroll a bit to ensure chart is fully visible if on small screen
        let scrollViews = app.scrollViews
        if scrollViews.firstMatch.exists {
            scrollViews.firstMatch.swipeUp()
        }
        snapshot("02_Dashboard_Chart")
        
        // 3. Calendar Tab
        let calendarTab = app.tabBars.buttons["Calendar"] // Accessibility identifier or label needed
        if calendarTab.exists {
            calendarTab.tap()
            snapshot("03_Calendar_View")
        } else {
            // Fallback: Try finding by icon or position if localized
            app.tabBars.buttons.element(boundBy: 1).tap()
            snapshot("03_Calendar_View")
        }
        
        // 4. Menu Tab
        let menuTab = app.tabBars.buttons["Menu"]
        if menuTab.exists {
            menuTab.tap()
            snapshot("04_Menu_View")
        } else {
             app.tabBars.buttons.element(boundBy: 2).tap()
             snapshot("04_Menu_View")
        }
    }
}
