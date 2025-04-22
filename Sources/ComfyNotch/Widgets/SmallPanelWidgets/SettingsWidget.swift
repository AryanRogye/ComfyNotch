import AppKit
import SwiftUI
import Combine

struct SettingsButtonView: View, Widget {

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
                .foregroundColor(Color(nsColor: model.playingColor))
                .background(Color.clear)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 20)
        .padding(.top, 2)
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}

class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        SettingsModel.shared.isSettingsWindowOpen = false
        SettingsModel.shared.refreshUI()
    }
}

class SettingsWidgetModel: ObservableObject {
    @Published var action: () -> Void
    @Published var playingColor: NSColor = .white

    private var cancellables = Set<AnyCancellable>()

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
        SettingsView(settings: SettingsModel.shared)
            .openNewWindow(
                title: "Settings",
                style: [.titled, .closable, .resizable],
                delegate: SettingsWindowDelegate()
            )
    }
}
