import AppKit
import SwiftUI
import Combine

struct SettingsButtonWidget: View, Widget {

    var name: String = "Settings"
    var alignment: WidgetAlignment? = .right

    // allow for function to run in here
    @ObservedObject var musicModel = MusicPlayerWidgetModel.shared
    @ObservedObject var settings = SettingsModel.shared
    @EnvironmentObject var settingsCoordinator: SettingsCoordinator

    var body: some View {
        Button(action: {
            settingsCoordinator.showSettings()
        }) {
            Image(systemName: "gear")
                .foregroundColor(Color(nsColor: musicModel.nowPlayingInfo.dominantColor))
        }
        .buttonStyle(.plain)
        .controlSize(.small)
        .padding(.trailing, settings.settingsWidgetDistanceFromRight)
        .padding(.top, settings.quickAccessWidgetDistanceFromTop)
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}
