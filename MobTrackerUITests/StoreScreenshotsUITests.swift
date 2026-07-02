//
//  StoreScreenshotsUITests.swift
//  MobTrackerUITests
//
//  Captures App Store screenshots (home / calendar / chart) in demo mode.
//  Attachments are exported from the .xcresult bundle with xcresulttool.
//

import XCTest

@MainActor
class StoreScreenshotsUITests: XCTestCase {

    func testCaptureStoreScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = ["--snapshot", "-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR"]
        app.launch()

        // Dismiss the notification permission alert if it appears (ko/en)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.buttons["허용"].exists
            ? springboard.buttons["허용"]
            : springboard.buttons["Allow"]
        if allowButton.waitForExistence(timeout: 5) {
            allowButton.tap()
        }

        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 10))
        sleep(3) // let demo data and layout settle

        capture(named: "01_home")

        tapTab(app, index: 1, labels: ["캘린더", "Calendar"])
        sleep(2)
        capture(named: "02_calendar")

        // Back to home, scrolled to the weekly comparison chart
        tapTab(app, index: 0, labels: ["홈", "Home"])
        sleep(1)
        app.scrollViews.firstMatch.swipeUp()
        sleep(2)
        capture(named: "03_chart")
    }

    // iPhone exposes a TabBar; iPadOS 18 renders TabView as top buttons.
    private func tapTab(_ app: XCUIApplication, index: Int, labels: [String]) {
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            tabBar.buttons.element(boundBy: index).tap()
            return
        }
        for label in labels {
            let button = app.buttons[label].firstMatch
            if button.exists {
                button.tap()
                return
            }
        }
        XCTFail("No tab control found for \(labels)")
    }

    private func capture(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
