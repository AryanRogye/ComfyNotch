import SwiftUI

/// -- Mark: Unused for now
struct CurrentSongWidget: View, Widget {
    var name: String = "CurrentSongWidget"

    @ObservedObject var model: MusicPlayerWidgetModel = .shared
    @ObservedObject var movingDotsModel: MovingDotsViewModel

    var body: some View {
        Text("\(model.songText)")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color(nsColor: movingDotsModel.playingColor))
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}
