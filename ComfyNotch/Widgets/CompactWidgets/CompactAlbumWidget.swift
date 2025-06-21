import AppKit
import SwiftUI
import Combine

struct CompactAlbumWidget: View, Widget {
    var alignment: WidgetAlignment? = .left
    var name: String = "AlbumWidget"

    @ObservedObject var model: MusicPlayerWidgetModel = .shared
    @ObservedObject var panelAnimationState: PanelAnimationState = .shared
    var scrollManager = ScrollHandler.shared

    var body: some View {
        ZStack {
            if !PanelAnimationState.shared.isExpanded {
                panelButton {
                    Image(nsImage: model.nowPlayingInfo.artworkImage ?? NSImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: panelAnimationState.isHoveringOverLeft ? 27 : 25, height: panelAnimationState.isHoveringOverLeft ? 24 : 22)
                        .cornerRadius(4)
                        .padding(.top, 2)
                        .opacity(model.nowPlayingInfo.artworkImage != nil ? 1 : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: panelAnimationState.isHoveringOverLeft)

                }
                
                panelButton {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 27, height: 23)
                        Image(systemName: "music.note")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 1)
                    .opacity(model.nowPlayingInfo.artworkImage == nil ? 1 : 0)
                }
            } else {
                Text("")
            }
        }
        .padding(.trailing, 22)
        .animation(.easeInOut(duration: 0.25), value: model.nowPlayingInfo.artworkImage != nil)
    }

    private func panelButton<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        Button(action: {
            withAnimation(Anim.spring) {
                UIManager.shared.applyOpeningLayout()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollManager.openFull()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    PanelAnimationState.shared.currentPanelState = .home
                }
            }
        }) {
            label()
        }
        .buttonStyle(.plain)
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}
