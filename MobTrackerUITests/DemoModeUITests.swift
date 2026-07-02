//
//  DemoModeUITests.swift
//  MobTrackerUITests
//
//  Verifies the App Store review demo mode: enter from the login screen,
//  browse the dashboard, and exit from the menu.
//

import XCTest

@MainActor
class DemoModeUITests: XCTestCase {

    func testEnterAndExitDemoMode() {
        let app = XCUIApplication()
        // Launch without --snapshot so the real login screen shows
        app.launchArguments = []
        app.launch()

        // Dismiss the notification permission alert if it appears (ko/en)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.buttons["허용"].exists
            ? springboard.buttons["허용"]
            : springboard.buttons["Allow"]
        if allowButton.waitForExistence(timeout: 5) {
            allowButton.tap()
        }

        // 1. Enter demo mode from the login screen
        let demoButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS '데모' OR label CONTAINS 'Demo'")
        ).firstMatch
        XCTAssertTrue(demoButton.waitForExistence(timeout: 10), "Demo button should be on the login screen")
        demoButton.tap()

        // 2. Dashboard should appear with the tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Dashboard tab bar should appear after entering demo mode")

        // 3. Calendar tab should render
        tabBar.buttons.element(boundBy: 1).tap()

        // 4. Menu tab should show the exit-demo button
        tabBar.buttons.element(boundBy: 2).tap()
        let exitButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS '데모 모드 종료' OR label CONTAINS 'Exit Demo'")
        ).firstMatch
        XCTAssertTrue(exitButton.waitForExistence(timeout: 5), "Menu should show the exit-demo button in demo mode")

        // 5. Exiting demo mode returns to the login screen
        exitButton.tap()
        XCTAssertTrue(demoButton.waitForExistence(timeout: 10), "Login screen should return after exiting demo mode")
    }
}
