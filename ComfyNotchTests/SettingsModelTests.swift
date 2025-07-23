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
    
    /// Function to test saving Notch Values
    func testSaving() {
        
        _testSaveClosedNotch()
        _testSaveOpenNotchDimensions()
        _testSaveOpeningAnimations()
        _testSaveMetalAnimationValues()
        _testSaveFileTrayValues()
        _testSaveMessagesValues()
        _testSaveUtilsValues()
        
        resetDefaults()
    }
    
    // MARK: - Test saveClosedNotchValues
    func _testSaveClosedNotch() {
        var values = ClosedNotchValues(
            notchMinWidth       : 270,
            hoverTargetMode     : .album,
            fallbackHeight      : 35,
            hudEnabled          : true,
            oneFingerAction     : .openSettings,
            twoFingerAction     : .openFileTray
        )
        
        settings.saveClosedNotchValues(values: values)
        settings.loadSettings()
        
        XCTAssertEqual(settings.notchMinWidth, settings.MIN_NOTCH_MIN_WIDTH)
        XCTAssertEqual(settings.hoverTargetMode, .album)
        XCTAssertEqual(settings.notchMinFallbackHeight, 35)
        XCTAssertEqual(settings.enableNotchHUD, true)
        XCTAssertEqual(settings.oneFingerAction.rawValue, TouchAction.openSettings.rawValue)
        XCTAssertEqual(settings.twoFingerAction.rawValue, TouchAction.openFileTray.rawValue)
        
        values = ClosedNotchValues(
            notchMinWidth       : Int(settings.MAX_NOTCH_MIN_WIDTH + 2.0),
            hoverTargetMode     : .album,
            fallbackHeight      : 35,
            hudEnabled          : true,
            oneFingerAction     : .openSettings,
            twoFingerAction     : .openFileTray
        )
        
        settings.saveClosedNotchValues(values: values)
        
        XCTAssertEqual(settings.notchMinWidth, settings.MAX_NOTCH_MIN_WIDTH)
        
        
        values = ClosedNotchValues(
            notchMinWidth       : 295,
            hoverTargetMode     : .album,
            fallbackHeight      : 35,
            hudEnabled          : true,
            oneFingerAction     : .openSettings,
            twoFingerAction     : .openFileTray
        )
        
        settings.saveClosedNotchValues(values: values)
        XCTAssertEqual(settings.notchMinWidth, 295)
    }
    
    // MARK: - Test Save OpenNotchContentDimensions
    func _testSaveOpenNotchDimensions() {
        var values = OpenNotchContentDimensionsValues(
            leftSpacing     : 20,
            rightSpacing    : 20,
            topSpacing      : 20,
            /// SHOULD NOT HAPPEN : SHOULD HIT 350
            notchMaxWidth   : 20
        )
        
        settings.saveOpenNotchContentDimensions(values: values)
        
        XCTAssertEqual(settings.quickAccessWidgetDistanceFromLeft , 20)
        XCTAssertEqual(settings.quickAccessWidgetDistanceFromTop, 20)
        XCTAssertEqual(settings.settingsWidgetDistanceFromRight, 20)
        XCTAssertEqual(settings.notchMaxWidth, settings.MIN_NOTCH_MAX_WIDTH)
        
        values = OpenNotchContentDimensionsValues(
            leftSpacing     : 20,
            rightSpacing    : 20,
            topSpacing      : 20,
            /// SHOULD NOT HAPPEN : SHOULD HIT 350
            notchMaxWidth   : 400
        )
        
        settings.saveOpenNotchContentDimensions(values: values)
        
        XCTAssertEqual(settings.notchMaxWidth, CGFloat(values.notchMaxWidth))
    }
    
    // MARK: - Test Save Opening Animations
    func _testSaveOpeningAnimations() {
        /// "spring" or "iOS"
        let values = OpeningAnimationSettingsValues(openingAnimation: "spring")
        
        settings.saveOpeningAnimationValues(values: values)
        
        XCTAssertEqual(settings.openingAnimation, values.openingAnimation)
    }
    
    
    // MARK: - Test Save Metal Animations
    func _testSaveMetalAnimationValues() {
        let values = MetalAnimationValues(
            enableMetalAnimation: true,
            notchBackgroundAnimation: .flowingLines,
            constant120FPS: true)
        
        settings.saveMetalAnimationValues(values: values)
        
        XCTAssertEqual(settings.enableMetalAnimation, values.enableMetalAnimation)
        XCTAssertEqual(settings.notchBackgroundAnimation.rawValue, values.notchBackgroundAnimation.rawValue)
        XCTAssertEqual(settings.constant120FPS, values.constant120FPS)
    }
    
    // MARK: - Test Save FileTray Values
    func _testSaveFileTrayValues() {
        let folderNames = ["ComfyTestA", "ComfyTestB", "ComfyTestC"]
        
        for name in folderNames {
            let testFolder = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent(name, isDirectory: true)
            
            let values = FileTraySettingsValues(
                fileTrayDefaultFolder: testFolder,
                fileTrayAllowOpenOnLocalhost: true,
                localHostPin: "pin-\(name)",
                fileTrayPort: Int.random(in: 6000...9999)
            )
            
            settings.saveFileTrayValues(values: values)
            
            XCTAssertEqual(settings.fileTrayDefaultFolder, testFolder)
            XCTAssertEqual(settings.fileTrayAllowOpenOnLocalhost, true)
            XCTAssertEqual(settings.localHostPin, "pin-\(name)")
            XCTAssertEqual(settings.fileTrayPort, values.fileTrayPort)
            
            // Clean up after each run
            try? FileManager.default.removeItem(at: testFolder)
        }
    }
    
    // MARK: - Test Saving Messages
    func _testSaveMessagesValues() {
        let values = MessagesSettingsValues(
            enableMessagesNotifications: true,
            messagesHandleLimit: 20,
            messagesMessageLimit: 50
        )
        
        settings.saveMessagesValues(values: values)
        
        XCTAssertEqual(settings.enableMessagesNotifications, values.enableMessagesNotifications)
        XCTAssertEqual(settings.messagesHandleLimit, values.messagesHandleLimit)
        XCTAssertEqual(settings.messagesMessageLimit, values.messagesMessageLimit)
    }
    
    // MARK: - Test Saving Utils
    func _testSaveUtilsValues() {
        let values = UtilsSettingsValues(
            enableUtilsOption: true,
            enableClipboardListener: true
        )
        
        settings.saveUtilsValues(values: values)
        
        XCTAssertEqual(settings.enableUtilsOption, values.enableUtilsOption)
        XCTAssertEqual(settings.enableClipboardListener, values.enableClipboardListener)
    }
    
    func _testQuickAccessDynamicSimpleValues() {
        var values = QuickAccessStyleValues(quickAccessWidgetSimpleDynamic: .simple)
        settings.saveQuickAcessSimpleDynamic(values: values)
        XCTAssertEqual(settings.quickAccessWidgetSimpleDynamic, values.quickAccessWidgetSimpleDynamic)
        
        values = QuickAccessStyleValues(quickAccessWidgetSimpleDynamic: .dynamic)
        settings.saveQuickAcessSimpleDynamic(values: values)
        XCTAssertEqual(settings.quickAccessWidgetSimpleDynamic, values.quickAccessWidgetSimpleDynamic)
    }
    
    func resetDefaults() {
        testDefaults.removePersistentDomain(forName: "com.aryan.test.settings")
    }
}
