import AppKit
import SwiftUI
import Combine

struct WidgetSizeConfig {
    let width: CGFloat
    let height: CGFloat
}

struct CompactAlbumWidget: View, Widget {
    var alignment: WidgetAlignment? = .left
    var name: String = "AlbumWidget"
    
    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    @ObservedObject var model: MusicPlayerWidgetModel = .shared
    @ObservedObject var notchStateManager: NotchStateManager = .shared
    var scrollManager = ScrollHandler.shared
    
    private var animationStiffness: CGFloat = 300
    private var animationDamping: CGFloat = 15
    
    private var paddingLeading: CGFloat {
        notchStateManager.hoverHandler.scaleHoverOverLeftItems ? 2 : 4
    }
    private var paddingTop: CGFloat {
        /// IF 0 it pushes it weirdly
        notchStateManager.hoverHandler.scaleHoverOverLeftItems ? 4 : 2
    }
    
    @State private var sizeConfig: WidgetSizeConfig = .init(width: 0, height: 0)
    
    var body: some View {
        panelButton {
            Group {
                if let artwork = model.nowPlayingInfo.artworkImage {
                    Image(nsImage: artwork)
                        .resizable()
                        .scaledToFit()
                        .frame(width: sizeConfig.width, height: sizeConfig.height)
                        .cornerRadius(4)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: sizeConfig.width, height: sizeConfig.height)
                        Image(systemName: "music.note")
                            .font(.system(size: sizeConfig.height * 0.5 > 0 ? sizeConfig.height * 0.5 : 1, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.leading, paddingLeading)
        .animation(
            .interpolatingSpring(stiffness: animationStiffness, damping: animationDamping),
            value: notchStateManager.hoverHandler.scaleHoverOverLeftItems
        )
        .onAppear { sizeConfig = widgetSize() }
        .onChange(of: notchStateManager.hoverHandler.scaleHoverOverLeftItems) {
            sizeConfig = widgetSize()
        }
        .padding(.top, paddingTop)
    }
    
    private func panelButton<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        Button(action: {
            withAnimation(Anim.spring) {
                UIManager.shared.applyOpeningLayout()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollManager.openFull()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    notchStateManager.currentPanelState = .home
                }
            }
        }) {
            label()
        }
        .buttonStyle(.plain)
    }
    
    func widgetSize() -> WidgetSizeConfig {
        let height = UIManager.shared.getNotchHeight()
        let w = height * 0.68
        let h = height * 0.68
        return .init(width: w,height: h)
    }
}
