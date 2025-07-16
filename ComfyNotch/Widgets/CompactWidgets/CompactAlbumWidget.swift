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
        notchStateManager.hoverHandler.scaleHoverOverLeftItems ? 1 : 0
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
        .animation(
            .interpolatingSpring(stiffness: animationStiffness, damping: animationDamping),
            value: notchStateManager.hoverHandler.scaleHoverOverLeftItems
        )
        .onAppear { sizeConfig = widgetSize() }
        .onChange(of: notchStateManager.hoverHandler.scaleHoverOverLeftItems) {
            sizeConfig = widgetSize()
        }
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
        guard let screen = DisplayManager.shared.selectedScreen else {
            return .init(width: 22, height: 25)
        }
        
        let scale = screen.backingScaleFactor
        let resolution = CGSize(width: screen.frame.width * scale,
                                height: screen.frame.height * scale)
        
        let w = resolution.width
        let isExpanded = notchStateManager.hoverHandler.scaleHoverOverLeftItems
        
        if w < 2800 {
            return isExpanded ? .init(width: 20, height: 20) : .init(width: 15, height: 14)
        } else if w <= 3500 {
            return isExpanded ? .init(width: 26, height: 23) : .init(width: 17, height: 17)
        } else {
            return isExpanded ? .init(width: 28, height: 25) : .init(width: 22, height: 23)
        }
    }
}
