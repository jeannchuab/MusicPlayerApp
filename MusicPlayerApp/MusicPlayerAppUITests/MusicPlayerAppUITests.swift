//
//  MusicPlayerAppUITests.swift
//  MusicPlayerAppUITests
//
//  Created by Jeann Luiz Chuab on 19/04/26.
//

import XCTest

final class MusicPlayerAppUITests: XCTestCase {

    // MARK: - XCTestCase

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Tests

    @MainActor
    func testHomeLoadsWithFixtureSongs() throws {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["Songs"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Midnight Signal"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Golden Static"].exists)
    }

    @MainActor
    func testEmptyFixtureModeRendersTheEmptyState() throws {
        let emptyApp = launchApp(arguments: ["--ui-testing", "--ui-testing-empty", "--skip-splash"])

        XCTAssertTrue(emptyApp.staticTexts["No songs found"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = defaultLaunchArguments
            app.launch()
        }
    }

    // MARK: - Helpers

    private var defaultLaunchArguments: [String] {
        ["--ui-testing", "--skip-splash"]
    }

    @discardableResult
    @MainActor
    private func launchApp(arguments: [String]? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = arguments ?? defaultLaunchArguments
        app.launch()
        return app
    }

    @MainActor
    private func element(in app: XCUIApplication, identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }
}
