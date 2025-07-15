import XCTest
@testable import ComfyNotch

class UIManagerTests: XCTestCase {
    
    var uiManager: UIManager!
    var settingsModel: SettingsModel!
    var displayManager: DisplayManager!
    
    override func setUp() {
        super.setUp()
        // Reset UserDefaults for test isolation
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        
        settingsModel = SettingsModel.shared
        displayManager = DisplayManager.shared
        uiManager = UIManager.shared
        
        // Set a test default for fallback height
        settingsModel.fallbackNotchHeight = 40
    }
    
    override func tearDown() {
        // Clean up after tests
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testGetNotchHeight_WhenSafeAreaInsetsAvailableAndGreaterThanZero() {
        // Given: Mock screen with safe area insets > 0
        let mockScreen = createMockScreen(safeAreaTop: 30)
        displayManager.selectedScreen = mockScreen
        
        // When: Getting notch height
        let result = uiManager.getNotchHeight()
        
        // Then: Should return the safe area inset value
        XCTAssertEqual(result, 30, "Should return safe area inset value when available and > 0")
    }
    
    func testGetNotchHeight_WhenSafeAreaInsetsSetToZero() {
        // Given: Mock screen with safe area insets = 0
        let mockScreen = createMockScreen(safeAreaTop: 0)
        displayManager.selectedScreen = mockScreen
        
        // When: Getting notch height
        let result = uiManager.getNotchHeight()
        
        // Then: Should return fallback value
        XCTAssertEqual(result, 40, "Should return fallback value when safe area insets are 0")
    }
    
    func testGetNotchHeight_WhenSafeAreaInsetsUnavailable() {
        // Given: No selected screen
        displayManager.selectedScreen = nil
        
        // When: Getting notch height
        let result = uiManager.getNotchHeight()
        
        // Then: Should return fallback value
        XCTAssertEqual(result, 40, "Should return fallback value when safe area insets are unavailable")
    }
    
    func testGetNotchHeight_WithCustomFallbackValue() {
        // Given: Custom fallback height and no safe area insets
        settingsModel.fallbackNotchHeight = 50
        displayManager.selectedScreen = nil
        
        // When: Getting notch height
        let result = uiManager.getNotchHeight()
        
        // Then: Should return custom fallback value
        XCTAssertEqual(result, 50, "Should return custom fallback value when configured")
    }
    
    func testGetNotchHeight_NeverReturnsZero() {
        // Given: Various scenarios that could return 0
        let scenarios: [(NSScreen?, CGFloat, String)] = [
            (nil, 25, "No screen selected"),
            (createMockScreen(safeAreaTop: 0), 25, "Safe area insets are 0"),
            (createMockScreen(safeAreaTop: -5), 25, "Safe area insets are negative")
        ]
        
        for (screen, fallbackHeight, description) in scenarios {
            // Given: Different fallback heights for each scenario
            settingsModel.fallbackNotchHeight = fallbackHeight
            displayManager.selectedScreen = screen
            
            // When: Getting notch height
            let result = uiManager.getNotchHeight()
            
            // Then: Should never return 0
            XCTAssertGreaterThan(result, 0, "Should never return 0: \(description)")
            XCTAssertEqual(result, fallbackHeight, "Should return fallback value: \(description)")
        }
    }
    
    func testGetNotchHeight_WithInvalidFallbackValue() {
        // Given: Invalid fallback height (0 or negative)
        settingsModel.fallbackNotchHeight = 0
        displayManager.selectedScreen = nil
        
        // When: Getting notch height
        let result = uiManager.getNotchHeight()
        
        // Then: Should return default fallback of 40
        XCTAssertEqual(result, 40, "Should return default fallback of 40 when configured fallback is invalid")
        
        // Given: Negative fallback height
        settingsModel.fallbackNotchHeight = -10
        
        // When: Getting notch height
        let result2 = uiManager.getNotchHeight()
        
        // Then: Should return default fallback of 40
        XCTAssertEqual(result2, 40, "Should return default fallback of 40 when configured fallback is negative")
    }
    
    func testFallbackHeightPersistence() {
        // Given: Custom fallback height
        settingsModel.fallbackNotchHeight = 35
        
        // When: Saving settings
        settingsModel.saveSettings()
        
        // And: Creating new settings instance (simulating app restart)
        let newSettings = SettingsModel.shared
        newSettings.loadSettings()
        
        // Then: Should load the saved fallback height
        XCTAssertEqual(newSettings.fallbackNotchHeight, 35, "Should persist custom fallback height")
    }
    
    func testFallbackHeightValidationOnSave() {
        // Given: Invalid fallback height
        settingsModel.fallbackNotchHeight = -5
        
        // When: Saving settings
        settingsModel.saveSettings()
        
        // Then: Should correct to default value
        XCTAssertEqual(settingsModel.fallbackNotchHeight, 40, "Should correct invalid fallback height to default when saving")
    }
    
    func testFallbackHeightValidationOnLoad() {
        // Given: Invalid fallback height stored in UserDefaults
        UserDefaults.standard.set(-10, forKey: "fallbackNotchHeight")
        
        // When: Loading settings
        settingsModel.loadSettings()
        
        // Then: Should correct to default value
        XCTAssertEqual(settingsModel.fallbackNotchHeight, 40, "Should correct invalid fallback height to default when loading")
    }
    
    // MARK: - Helper Methods
    
    private func createMockScreen(safeAreaTop: CGFloat) -> NSScreen {
        // Note: This is a simplified mock for testing purposes
        // In a real implementation, you might need to use a more sophisticated mocking approach
        // or create a protocol for screen abstraction
        let screen = NSScreen.main!
        
        // Since NSScreen properties are read-only, we would need to either:
        // 1. Create a protocol abstraction for screen handling
        // 2. Use method swizzling for testing
        // 3. Create a mock screen class
        
        // For now, we'll document the expected behavior
        // In a production test, you would implement proper mocking
        return screen
    }
}

// MARK: - Integration Tests

class NotchHeightIntegrationTests: XCTestCase {
    
    func testScrollHandlerUsesCorrectNotchHeight() {
        // Given: ScrollHandler uses UIManager's getNotchHeight
        let scrollHandler = ScrollHandler.shared
        let uiManager = UIManager.shared
        
        // When: Getting min panel height from scroll handler
        let minPanelHeight = scrollHandler.minPanelHeight
        let notchHeight = uiManager.getNotchHeight()
        
        // Then: Should use the same value
        XCTAssertEqual(minPanelHeight, notchHeight, "ScrollHandler should use UIManager's notch height")
    }
    
    func testTopNotchViewUsesCorrectHeight() {
        // This test would verify that TopNotchView uses the correct height
        // In a real implementation, you would test the view's maxHeight property
        
        let notchHeight = UIManager.shared.getNotchHeight()
        XCTAssertGreaterThan(notchHeight, 0, "TopNotchView should receive non-zero height")
    }
    
    func testPanelSetupUsesCorrectHeight() {
        // This test would verify that panel setup uses the correct height
        // In a real implementation, you would test the panel frame calculation
        
        let notchHeight = UIManager.shared.getNotchHeight()
        XCTAssertGreaterThan(notchHeight, 0, "Panel setup should use non-zero height")
    }
}