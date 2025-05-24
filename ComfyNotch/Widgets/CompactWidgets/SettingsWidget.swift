import AppKit
import SwiftUI
import Combine

struct SettingsButtonWidget: View, Widget {

    var name: String = "Settings"
    var alignment: WidgetAlignment? = .right

    // allow for function to run in here
    @ObservedObject var model = MusicPlayerWidgetModel.shared
    @Environment(\.openWindow) var openWindow

    var body: some View {
        Button(action: {
            openWindow(id: "SettingsView")
        }) {
            Image(systemName: "gear")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 15)
                .foregroundColor(Color(nsColor: model.nowPlayingInfo.dominantColor))
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
