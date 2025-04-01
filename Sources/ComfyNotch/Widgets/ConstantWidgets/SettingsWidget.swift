import AppKit
import SwiftUI

struct SettingsButtonView : View {

    // allow for function to run in here
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gear")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
        }
    }
}

class SettingsWidget : NSObject, Widget {

    var name: String = "Settings"
    var view: NSView

    private var hostingController: NSHostingController<SettingsButtonView>

    private var _alignment: WidgetAlignment = .right
    private var settingsWindow: NSWindow?



    var alignment: WidgetAlignment? {
        get { return _alignment }
        set { 
            if let newValue = newValue {
                _alignment = newValue
                print("Setting alignment to: \(newValue)")
            }
        }
    }

    override init() {
        view = NSView() // Temporary placeholder
        hostingController = NSHostingController(rootView: SettingsButtonView(action: {}))
        
        super.init()

        let swiftUIView = SettingsButtonView(action: { [weak self] in self?.openSettings() })
        hostingController = NSHostingController(rootView: swiftUIView)
        
        let hostingView = hostingController.view
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view = hostingView
        
        view.isHidden = true
    }


    @objc func openSettings() {
        print("Opening settings")

        // Check if the window is already open to prevent multiple instances
        if settingsWindow != nil {
            settingsWindow?.makeKeyAndOrderFront(nil)
            settingsWindow?.orderFrontRegardless() // Ensures it appears above everything else
            return
        }

        // Create a new SwiftUI window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()
        window.isReleasedWhenClosed = false

        // Make sure the window is displayed above your fullscreen app
        window.level = .floating  // This ensures it shows on top

        // Set SwiftUI view as the window's content using NSHostingController
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        window.contentViewController = hostingController

        // Store a reference to the window so it's not immediately deallocated
        self.settingsWindow = window

        // Add the window to the app's windows to retain it properly
        NSApp.addWindowsItem(window, title: window.title, filename: false)

        // Show the window
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless() // Ensures it appears above everything else
        print("Settings window opened")
    }

    private func createStyledButton(symbolName: String, action: Selector) -> NSButton {
        let button = NSButton()
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)

        if image == nil {
            print("Error: Failed to load system symbol '\(symbolName)'")
        }

        button.image = image
        button.target = self
        button.action = action
        button.wantsLayer = true
        button.isBordered = false
        button.layer?.cornerRadius = 8
        button.contentTintColor = .white // Make sure tint color is visible
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.isEnabled = true
        button.setButtonType(.momentaryPushIn)

        return button
    }

    func update() {

    }

    func show() {
        view.isHidden = false
    }

    func hide() {
        view.isHidden = true
    }

}