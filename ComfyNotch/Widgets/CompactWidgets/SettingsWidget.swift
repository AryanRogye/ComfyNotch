import AppKit
import SwiftUI
import Combine

struct SettingsButtonWidget: View, Widget {

    var name: String = "Settings"
    var alignment: WidgetAlignment? = .right

    // allow for function to run in here
    @ObservedObject var musicModel = MusicPlayerWidgetModel.shared
    @ObservedObject var settings = SettingsModel.shared
    @Environment(\.openWindow) var openWindow

    var body: some View {
        Button(action: {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "SettingsView")
        }) {
            Image(systemName: "gear")
                .foregroundColor(Color(nsColor: musicModel.nowPlayingInfo.dominantColor))
        }
        .buttonStyle(.plain)
        .controlSize(.extraLarge)
        .padding(.trailing, settings.settingsWidgetDistanceFromRight)
        .padding(.top, settings.quickAccessWidgetDistanceFromTop)
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}
