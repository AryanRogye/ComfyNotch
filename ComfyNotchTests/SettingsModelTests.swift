//
//  SettingsModelTests.swift
//  ComfyNotchTests
//
//  Created by Aryan Rogye on 7/15/25.
//

import XCTest
@testable import ComfyNotch

final class SettingsModelTests: XCTestCase {
    
    var testDefaults: UserDefaults!
    var settings: SettingsModel!
    
    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "com.aryan.test.settings")
        testDefaults.removePersistentDomain(forName: "com.aryan.test.settings")
        
        settings = SettingsModel(userDefaults: testDefaults)
    }
    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "com.aryan.test.settings")
        testDefaults = nil
        settings = nil
        super.tearDown()
    }

    func testFreshLaunchDefaults() {
        XCTAssertEqual(settings.notchMinFallbackHeight, 40)
        XCTAssertEqual(settings.cameraOverlayTimer, 20)
        XCTAssertEqual(settings.selectedWidgets, WidgetRegistry.shared.getDefaultWidgets())
        XCTAssertEqual(settings.selectedWidgets.count, 1)
        XCTAssertTrue(settings.enableCameraOverlay)
        XCTAssertTrue(!settings.enableClipboardListener)
        XCTAssertFalse(settings.enableMessagesNotifications)
    }
}
