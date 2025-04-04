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

class FocusableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static let shared = SettingsWindowController()
    
    private init() {
        let settingsView = SettingsView() // Your SwiftUI view
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = FocusableWindow(contentViewController: hostingController)
        window.title = "Settings"
        window.setContentSize(NSSize(width: 400, height: 600))
        window.styleMask = [.titled, .closable, .resizable]
        window.level = .floating
        window.isReleasedWhenClosed = false
        
        super.init(window: window)
        
        window.delegate = self
    }

    deinit {
        SettingsModel.shared.isSettingsOpen = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        guard let window = self.window else { return }
        
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        
        NSApp.activate(ignoringOtherApps: true) // Make sure your app is the focused application

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            window.makeFirstResponder(window.contentView)
        }
        
        SettingsModel.shared.isSettingsOpen = true // Make sure to update the model when opening
    }

    func windowWillClose(_ notification: Notification) {
        SettingsModel.shared.isSettingsOpen = false
    }
}

class SettingsWidget : NSObject, Widget {

    var name: String = "Settings"
    var view: NSView

    private var hostingController: NSHostingController<SettingsButtonView>

    private var _alignment: WidgetAlignment = .right
    var settingsWindow: NSWindow?



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

        // // Check if the window is already open to prevent multiple instances
        // if let existingWindow = settingsWindow {
        //     existingWindow.makeKeyAndOrderFront(nil)
        //     existingWindow.orderFrontRegardless()
        //     SettingsModel.shared.isSettingsOpen = true
        //     return
        // }

        // // Create a new SwiftUI window
        // let window = NSWindow(
        //     contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
        //     styleMask: [.titled, .closable, .resizable],
        //     backing: .buffered,
        //     defer: false
        // )
        // window.title = "Settings"

        // window.isReleasedWhenClosed = false // Keep it in memory even after closing

        // // ✅ Assign the delegate to this class (make sure your class conforms to NSWindowDelegate)
        // window.delegate = self

        // window.level = .floating

        // let settingsView = SettingsView()
        // let hostingController = NSHostingController(rootView: settingsView)
        // window.contentViewController = hostingController

        // if let screen = NSScreen.main {
        //     let screenFrame = screen.visibleFrame
            
        //     // Calculate window position
        //     let windowWidth: CGFloat = 400
        //     let windowHeight: CGFloat = 300
        //     let xPos = (screenFrame.width - windowWidth) / 2
            
        //     // Position about 200 pixels up from the bottom of the screen
        //     let yPos: CGFloat = 200
            
        //     // Force set frame completely instead of just origin
        //     window.setFrame(NSRect(x: xPos, y: yPos, width: windowWidth, height: windowHeight), display: true)
        // }

        // // Make sure this is called after setting the frame
        // window.center()


        // self.settingsWindow = window
        // NSApp.addWindowsItem(window, title: window.title, filename: false)
        // window.makeKeyAndOrderFront(nil)
        // window.orderFrontRegardless()

        // // After window is visible, force position again with a slight delay
        // DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        //     if let screen = NSScreen.main {
        //         let screenFrame = screen.visibleFrame
        //         let xPos = (screenFrame.width - 400) / 2
        //         let yPos: CGFloat = 200
        //         self?.settingsWindow?.setFrameOrigin(NSPoint(x: xPos, y: yPos))
        //     }
        // }

        SettingsWindowController.shared.show()
        
        SettingsModel.shared.isSettingsOpen = true
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


extension SettingsWidget: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow == self.settingsWindow {
            SettingsModel.shared.isSettingsOpen = false
            self.settingsWindow = nil // Clear the reference to the settings window
            print("Settings window closed via red X button")
        }
    }
}