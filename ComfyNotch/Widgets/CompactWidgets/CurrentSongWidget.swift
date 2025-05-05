import SwiftUI

/// -- Mark: Unused for now
struct CurrentSongWidget: View, Widget {
    var name: String = "CurrentSongWidget"

    @ObservedObject var model: MusicPlayerWidgetModel = .shared

    var body: some View {
        Text("\(model.nowPlayingInfo.trackName)")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color(nsColor: model.nowPlayingInfo.dominantColor))
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}
