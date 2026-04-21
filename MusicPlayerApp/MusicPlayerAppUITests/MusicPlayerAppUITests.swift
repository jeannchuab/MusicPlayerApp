//
//  MusicPlayerAppUITests.swift
//  MusicPlayerAppUITests
//
//  Created by Jeann Luiz Chuab on 19/04/26.
//

import XCTest

final class MusicPlayerAppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testHomeLoadsWithFixtureSongs() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--skip-splash"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Songs"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Midnight Signal"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Golden Static"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-testing", "--skip-splash"]
            app.launch()
        }
    }
}
