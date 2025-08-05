//
//  MusicPlayerUITests.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/3/25.
//

import XCTest

final class MusicPlayerUITests: XCTestCase {
    
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
    func testNativeAndComfyStyleSwitch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["--uitest-selectedTab", "widgetSettings"]
        
        app.activate()
        
        let albumWidgetButton = app.buttons["[CompactAlbumWidget] Open FileTray"].firstMatch
        XCTAssert(albumWidgetButton.waitForExistence(timeout: 5), "Album Widget Should Exist")
        
        app.buttons["[CompactAlbumWidget] Open FileTray"].firstMatch.click()
        app.buttons["gear"].firstMatch.click()
        
        let musicSaveButton = app.buttons["MusicPlayerSettingsSaveButton"].firstMatch
        let nativeButton = app.buttons["NativeStyleButton"].firstMatch
        let comfyButton = app.buttons["ComfyStyleButton"].firstMatch
        
        let nativeStyleWidget = app.buttons["NativeStyleMusicWidget"].firstMatch
        let comfyStyleWidget = app.buttons["ComfyStyleMusicWidget"].firstMatch

        /// This will make sure that it just defaults to Native now we can test switch on both
        nativeButton.click()
        musicSaveButton.click()
        
        /// Test Comfy Style
        comfyButton.click()
        musicSaveButton.click()
        XCTAssertTrue(comfyStyleWidget.waitForExistence(timeout: 2), "\(comfyStyleWidget.title) Doesnt Exist But Should After Save")
        
        nativeButton.click()
        musicSaveButton.click()
        XCTAssertTrue(nativeStyleWidget.waitForExistence(timeout: 2), "\(nativeStyleWidget.title) Doesnt Exist But Should After Save")
    }
}
