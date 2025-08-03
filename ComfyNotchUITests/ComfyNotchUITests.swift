//
//  ComfyNotchUITests.swift
//  ComfyNotchUITests
//
//  Created by Aryan Rogye on 8/3/25.
//

import XCTest

final class ComfyNotchUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    @MainActor
    func testClickingAlbumOpensPanel() throws {
        let app = XCUIApplication()
        app.launch()
        
        let albumButton = app.buttons["[CompactAlbumWidget] Open FileTray"].firstMatch
        
        // Wait up to 5 seconds for the button to exist
        XCTAssertTrue(albumButton.waitForExistence(timeout: 5), "Album button should appear")
        XCTAssert(albumButton.exists, "Album button should exist")
        XCTAssert(albumButton.isHittable, "Album button should be hittable")
        
        albumButton.click()
        XCTAssertFalse(albumButton.exists, "Album button should disappear after opening panel")
    }
}
