import AppKit
import SwiftUI

struct SettingsButtonView : View, SwiftUIWidget {

    var name: String = "Settings"
    var alignment: WidgetAlignment? = .right

    // allow for function to run in here
    @ObservedObject var model: SettingsWidgetModel

    var body: some View {
        Button(action: model.action) {
            Image(systemName: "gear")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 15)
                .foregroundColor(.white)
                .background(Color.clear)
        }
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }    
}

class SettingsWidgetModel: ObservableObject {
    @Published var action : () -> Void = {
        SettingsWindowController.shared.show()
        SettingsModel.shared.isSettingsWindowOpen = true
    }
}

class FocusableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    // This is the key: use `override var acceptsFirstResponder: Bool`
    override var acceptsFirstResponder: Bool {
        return true
    }

    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        makeFirstResponder(contentView)
    }
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
        SettingsModel.shared.isSettingsWindowOpen = false
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
            if self != nil {
                window.makeFirstResponder(window.contentView)
            }
        }
        
        SettingsModel.shared.isSettingsWindowOpen = true // Make sure to update the model when opening
    }

    func windowWillClose(_ notification: Notification) {
        SettingsModel.shared.isSettingsWindowOpen = false
    }
}