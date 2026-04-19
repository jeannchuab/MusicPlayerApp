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

        XCTAssertTrue(app.navigationBars["Songs"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any)["home.songList"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Midnight Signal"].exists)
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
