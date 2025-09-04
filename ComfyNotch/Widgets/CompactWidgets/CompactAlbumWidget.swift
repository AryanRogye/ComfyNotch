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
    @ObservedObject var scrollManager = ScrollManager.shared
    
    private var animationStiffness: CGFloat = 300
    private var animationDamping: CGFloat = 15
    
    private var paddingLeading: CGFloat {
        notchStateManager.hoverHandler.scaleHoverOverLeftItems ? 5 : 4
    }
    private var paddingTop: CGFloat {
        /// IF 0 it pushes it weirdly
        notchStateManager.hoverHandler.scaleHoverOverLeftItems ? 3 : 3
    }
    
    @State private var scale: CGFloat = 1.0
    
    @State private var sizeConfig: WidgetSizeConfig = .init(width: 0, height: 0)
    
    var body: some View {
        panelButton {
            Group {
                if let artwork = model.nowPlayingInfo.artworkImage {
                    Image(nsImage: artwork)
                        .resizable()
                        .frame(width: sizeConfig.width, height: sizeConfig.height)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .cornerRadius(4)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: sizeConfig.width, height: sizeConfig.height)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Image(systemName: "music.note")
                            .font(.system(size: sizeConfig.height * 0.5 > 0 ? sizeConfig.height * 0.5 : 1, weight: .medium))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
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
        .onChange(of: notchStateManager.hoverHandler.scaleHoverOverLeftItems) { _, value in
            if value {
                let size = widgetSize()
                withAnimation(.interpolatingSpring(stiffness: 180, damping: 20)) {
                    sizeConfig = .init(width: size.width * 1.1, height: size.height * 1.1)
                }
            } else {
                withAnimation(.interpolatingSpring(stiffness: 180, damping: 20)) {
                    sizeConfig = widgetSize()
                }
            }
        }
        .onChange(of: notchStateManager.hoverHandler.scaleHoverOverLeftItems) { _, value in
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 20)) {
                scale = value ? 1.3 : 1.0
            }
        }
        .padding(.top, paddingTop)
    }
    
    private func panelButton<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        Button(action: {
            NotchStateManager.shared.hoverHandler.usedButtonToOpen = true
            NotchStateManager.shared.handleScrollDown(translation: 20, phase: NSEvent.Phase(rawValue: 0), force: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                NotchStateManager.shared.hoverHandler.usedButtonToOpen = false
            }
        }) {
            label()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("[CompactAlbumWidget] Open FileTray")
    }
    
    func widgetSize() -> WidgetSizeConfig {
        let height = ScrollManager.shared.getNotchHeight()
        let w = height * 0.65
        let h = height * 0.65
        
        return .init(width: w,height: h)
    }
}
