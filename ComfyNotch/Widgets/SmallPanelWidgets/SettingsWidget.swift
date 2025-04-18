import AppKit
import SwiftUI
import Combine

struct SettingsButtonView: View, Widget {

    var name: String = "Settings"
    var alignment: WidgetAlignment? = .right

    // allow for function to run in here
    @ObservedObject var model = SettingsWidgetModel.shared

    var body: some View {
        Button(action: model.action) {
            Image(systemName: "gear")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 15)
                .foregroundColor(Color(nsColor: model.playingColor))
                .background(Color.clear)
        }
        .buttonStyle(.plain)
        .padding(.top, 2)
        .padding(.trailing, 20)
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}

class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        // Immediate teardown
        SettingsModel.shared.isSettingsWindowOpen = false
        SettingsModel.shared.refreshUI()
        
        // And schedule a follow‑up UI refresh in 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            SettingsModel.shared.refreshUI()
        }
    }
}

class SettingsWidgetModel: ObservableObject {
    static let shared = SettingsWidgetModel()

    @Published var action: () -> Void
    @Published var playingColor: NSColor = .white

    private var cancellables = Set<AnyCancellable>()
    
    private static var settingsWindow: NSWindow?

    init() {
        action = {
            Self.openSettingsWindow()
        }

        AudioManager.shared.$dominantColor
            .receive(on: RunLoop.main)
            .sink { [weak self] color in
                self?.playingColor = color
            }
            .store(in: &cancellables)
    }

    private static func openSettingsWindow() {
        SettingsModel.shared.isSettingsWindowOpen = true
        
        let window = SettingsView(settings: SettingsModel.shared)
            .newWindowInternal(
                title: "Settings",
                geometry: NSRect(x: 100, y: 100, width: 600, height: 400),
                style: [.titled, .closable, .resizable],
                delegate: SettingsWindowDelegate()
            )
        
        settingsWindow = window
        settingsWindow?.contentView = NSHostingView(rootView: SettingsView(settings: SettingsModel.shared))
    }
}
