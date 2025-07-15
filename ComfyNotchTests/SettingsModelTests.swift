import XCTest
@testable import ComfyNotch

class SettingsModelTests: XCTestCase {
    
    var settingsModel: SettingsModel!
    
    override func setUp() {
        super.setUp()
        // Reset UserDefaults for test isolation
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        settingsModel = SettingsModel.shared
    }
    
    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        super.tearDown()
    }
    
    // MARK: - Fallback Height Tests
    
    func testFallbackNotchHeightDefaultValue() {
        // Given: Fresh settings model
        // When: Accessing fallback height
        let fallbackHeight = settingsModel.fallbackNotchHeight
        
        // Then: Should have default value of 40
        XCTAssertEqual(fallbackHeight, 40, "Default fallback height should be 40")
    }
    
    func testFallbackNotchHeightCanBeSet() {
        // Given: Custom fallback height
        let customHeight: CGFloat = 50
        
        // When: Setting fallback height
        settingsModel.fallbackNotchHeight = customHeight
        
        // Then: Should be set correctly
        XCTAssertEqual(settingsModel.fallbackNotchHeight, customHeight, "Should be able to set custom fallback height")
    }
    
    func testFallbackNotchHeightPersistence() {
        // Given: Custom fallback height
        let customHeight: CGFloat = 45
        settingsModel.fallbackNotchHeight = customHeight
        
        // When: Saving settings
        settingsModel.saveSettings()
        
        // And: Loading settings
        settingsModel.loadSettings()
        
        // Then: Should persist the value
        XCTAssertEqual(settingsModel.fallbackNotchHeight, customHeight, "Fallback height should persist across save/load cycles")
    }
    
    func testFallbackNotchHeightValidationOnSave() {
        // Given: Invalid fallback height values
        let invalidValues: [CGFloat] = [0, -5, -10, -100]
        
        for invalidValue in invalidValues {
            // Given: Invalid fallback height
            settingsModel.fallbackNotchHeight = invalidValue
            
            // When: Saving settings
            settingsModel.saveSettings()
            
            // Then: Should be corrected to default
            XCTAssertEqual(settingsModel.fallbackNotchHeight, 40, "Invalid fallback height \(invalidValue) should be corrected to 40 on save")
        }
    }
    
    func testFallbackNotchHeightValidationOnLoad() {
        // Given: Invalid values stored in UserDefaults
        let invalidValues: [CGFloat] = [0, -5, -10, -100]
        
        for invalidValue in invalidValues {
            // Given: Invalid value in UserDefaults
            UserDefaults.standard.set(invalidValue, forKey: "fallbackNotchHeight")
            
            // When: Loading settings
            settingsModel.loadSettings()
            
            // Then: Should be corrected to default
            XCTAssertEqual(settingsModel.fallbackNotchHeight, 40, "Invalid fallback height \(invalidValue) should be corrected to 40 on load")
        }
    }
    
    func testFallbackNotchHeightValidValues() {
        // Given: Valid fallback height values
        let validValues: [CGFloat] = [1, 10, 25, 40, 50, 100, 200]
        
        for validValue in validValues {
            // Given: Valid fallback height
            settingsModel.fallbackNotchHeight = validValue
            
            // When: Saving settings
            settingsModel.saveSettings()
            
            // Then: Should remain unchanged
            XCTAssertEqual(settingsModel.fallbackNotchHeight, validValue, "Valid fallback height \(validValue) should remain unchanged on save")
            
            // And: Should persist correctly
            settingsModel.loadSettings()
            XCTAssertEqual(settingsModel.fallbackNotchHeight, validValue, "Valid fallback height \(validValue) should persist correctly")
        }
    }
    
    func testFallbackNotchHeightLoadingFromEmptyUserDefaults() {
        // Given: No fallback height stored in UserDefaults
        UserDefaults.standard.removeObject(forKey: "fallbackNotchHeight")
        
        // When: Loading settings
        settingsModel.loadSettings()
        
        // Then: Should use default value
        XCTAssertEqual(settingsModel.fallbackNotchHeight, 40, "Should use default fallback height when none is stored")
    }
    
    // MARK: - Integration with Other Settings
    
    func testFallbackNotchHeightDoesNotAffectOtherSettings() {
        // Given: Various settings values
        let originalNotchMaxWidth = settingsModel.notchMaxWidth
        let originalShowDivider = settingsModel.showDividerBetweenWidgets
        
        // When: Setting fallback height
        settingsModel.fallbackNotchHeight = 60
        settingsModel.saveSettings()
        
        // Then: Other settings should remain unchanged
        XCTAssertEqual(settingsModel.notchMaxWidth, originalNotchMaxWidth, "Fallback height change should not affect notch max width")
        XCTAssertEqual(settingsModel.showDividerBetweenWidgets, originalShowDivider, "Fallback height change should not affect other settings")
    }
    
    func testSettingsModelIntegrity() {
        // Given: Multiple settings including fallback height
        settingsModel.fallbackNotchHeight = 35
        settingsModel.notchMaxWidth = 750
        settingsModel.showDividerBetweenWidgets = true
        
        // When: Saving and loading
        settingsModel.saveSettings()
        settingsModel.loadSettings()
        
        // Then: All settings should be preserved
        XCTAssertEqual(settingsModel.fallbackNotchHeight, 35, "Fallback height should be preserved")
        XCTAssertEqual(settingsModel.notchMaxWidth, 750, "Notch max width should be preserved")
        XCTAssertEqual(settingsModel.showDividerBetweenWidgets, true, "Show divider setting should be preserved")
    }
    
    // MARK: - Edge Cases
    
    func testFallbackNotchHeightWithFloatingPointValues() {
        // Given: Floating point values
        let floatingValues: [CGFloat] = [1.5, 25.7, 40.0, 100.25]
        
        for floatingValue in floatingValues {
            // Given: Floating point fallback height
            settingsModel.fallbackNotchHeight = floatingValue
            
            // When: Saving and loading
            settingsModel.saveSettings()
            settingsModel.loadSettings()
            
            // Then: Should preserve the exact value
            XCTAssertEqual(settingsModel.fallbackNotchHeight, floatingValue, accuracy: 0.01, "Should preserve floating point fallback height \(floatingValue)")
        }
    }
    
    func testFallbackNotchHeightWithVeryLargeValues() {
        // Given: Large values
        let largeValues: [CGFloat] = [1000, 5000, 10000]
        
        for largeValue in largeValues {
            // Given: Large fallback height
            settingsModel.fallbackNotchHeight = largeValue
            
            // When: Saving and loading
            settingsModel.saveSettings()
            settingsModel.loadSettings()
            
            // Then: Should preserve the value (no upper limit validation)
            XCTAssertEqual(settingsModel.fallbackNotchHeight, largeValue, "Should preserve large fallback height \(largeValue)")
        }
    }
    
    func testFallbackNotchHeightThreadSafety() {
        // Given: Concurrent access expectation
        let expectation = expectation(description: "Concurrent access should be safe")
        expectation.expectedFulfillmentCount = 10
        
        // When: Multiple concurrent accesses
        for i in 1...10 {
            DispatchQueue.global().async {
                let value = CGFloat(i * 10)
                self.settingsModel.fallbackNotchHeight = value
                
                // Verify the value was set (may not be the exact value due to concurrency)
                XCTAssertGreaterThan(self.settingsModel.fallbackNotchHeight, 0, "Should always have a positive value")
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}

// MARK: - Performance Tests

class SettingsModelPerformanceTests: XCTestCase {
    
    var settingsModel: SettingsModel!
    
    override func setUp() {
        super.setUp()
        settingsModel = SettingsModel.shared
    }
    
    func testFallbackNotchHeightGetterPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = settingsModel.fallbackNotchHeight
            }
        }
    }
    
    func testFallbackNotchHeightSetterPerformance() {
        measure {
            for i in 0..<1000 {
                settingsModel.fallbackNotchHeight = CGFloat(40 + i % 10)
            }
        }
    }
    
    func testFallbackNotchHeightSavePerformance() {
        settingsModel.fallbackNotchHeight = 45
        
        measure {
            for _ in 0..<100 {
                settingsModel.saveSettings()
            }
        }
    }
    
    func testFallbackNotchHeightLoadPerformance() {
        settingsModel.fallbackNotchHeight = 45
        settingsModel.saveSettings()
        
        measure {
            for _ in 0..<100 {
                settingsModel.loadSettings()
            }
        }
    }
}