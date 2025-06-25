import AppKit
import SwiftUI
import Combine

struct CompactAlbumWidget: View, Widget {
    var alignment: WidgetAlignment? = .left
    var name: String = "AlbumWidget"

    @ObservedObject var model: MusicPlayerWidgetModel = .shared
    @ObservedObject var panelAnimationState: PanelAnimationState = .shared
    var scrollManager = ScrollHandler.shared
    
    private let smallSizeWidth: CGFloat = 25
    private let smallSizeHeight: CGFloat = 22
    private let bigSizeWidth: CGFloat = 28
    private let bigSizeHeight: CGFloat = 25
    
    private var width: CGFloat {
        panelAnimationState.hoverHandler.scaleHoverOverLeftItems ? bigSizeWidth : smallSizeWidth
    }
    
    private var height: CGFloat {
        panelAnimationState.hoverHandler.scaleHoverOverLeftItems ? bigSizeHeight : smallSizeHeight
    }
    
    private var animationStiffness: CGFloat = 300
    private var animationDamping: CGFloat = 15
    
    private var paddingLeading: CGFloat {
        panelAnimationState.hoverHandler.scaleHoverOverLeftItems ? 2 : 4
    }
    private var paddingTop: CGFloat {
        panelAnimationState.hoverHandler.scaleHoverOverLeftItems ? 1 : 0
    }
    

    var body: some View {
        panelButton {
            Group {
                if let artwork = model.nowPlayingInfo.artworkImage {
                    Image(nsImage: artwork)
                        .resizable()
                        .scaledToFit()
                        .frame(width: width, height: height)
                        .cornerRadius(4)
                        .padding(.top, 2)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 27, height: 23)
                        Image(systemName: "music.note")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 1)
                }
            }
        }
        .padding(.leading, paddingLeading)
//        .padding(.top, paddingTop)
        .animation(
            .interpolatingSpring(stiffness: animationStiffness, damping: animationDamping),
            value: panelAnimationState.hoverHandler.scaleHoverOverLeftItems
        )
    }

    private func panelButton<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        Button(action: {
            withAnimation(Anim.spring) {
                UIManager.shared.applyOpeningLayout()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollManager.openFull()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    panelAnimationState.currentPanelState = .home
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
