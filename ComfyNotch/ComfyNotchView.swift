import AppKit
import SwiftUI
import Combine
import MetalKit

class PanelAnimationState: ObservableObject {
    static let shared = PanelAnimationState()

    @Published var isExpanded: Bool = false
    @Published var bottomSectionHeight: CGFloat = 0
    @Published var songText: String = AudioManager.shared.currentSongText
    @Published var playingColor: NSColor = AudioManager.shared.dominantColor

    private var cancellables = Set<AnyCancellable>()

    init() {
        AudioManager.shared.$currentSongText
            .receive(on: RunLoop.main)
            .sink { [weak self] newSong in
                self?.songText = newSong
            }
            .store(in: &cancellables)

        AudioManager.shared.$dominantColor
            .receive(on: RunLoop.main)
            .sink { [weak self] color in
                DispatchQueue.main.async {
                    self?.playingColor = color
                }
            }
            .store(in: &cancellables)
    }
}

struct ComfyNotchView: View {

    @EnvironmentObject var widgetStore: CompactWidgetsStore
    @EnvironmentObject var bigWidgetStore: ExpandedWidgetsStore

    @ObservedObject var animationState = PanelAnimationState.shared
    @State private var isHovering: Bool = false

    private var paddingWidth: CGFloat = 20
    private var contentInset: CGFloat = 40

    var body: some View {
        ZStack {
//           if animationState.isExpanded {
//               GeometryReader { geo in
//                   MetalBackgroundView(shade: $animationState.playingColor)
//                       .frame(width: geo.size.width, height: geo.size.height)
//                       .allowsHitTesting(false)
//                   Image("noise")
//                       .resizable()
//                       .scaledToFill()
//                       .opacity(0.05)
//                       .blendMode(.overlay)
//               }
//           } else {
            Color.black.opacity(0.9)
                .clipShape(RoundedCornersShape(
                    topLeft: 0,
                    topRight: 0,
                    bottomLeft: 10,
                    bottomRight: 10
                ))
//           }
            VStack(spacing: 0) {
                /// Top Row Widgets
                renderTopRow()
                renderBottomWidgets()
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedCornersShape(
                        topLeft: 0,
                        topRight: 0,
                        bottomLeft: 10,
                        bottomRight: 10
                 ))
        .mask(
            RoundedCornersShape(
                topLeft: 0,
                topRight: 0,
                bottomLeft: 10,
                bottomRight: 10
            )
        )
        /// For Scrolling the Panel
        .panGesture(direction: .down) { delta, phase in
            ScrollHandler.shared.handlePan(delta: delta, phase: phase)
        }
        .panGesture(direction: .up) { delta, phase in
            ScrollHandler.shared.handlePan(delta: -delta, phase: phase)
        }
    }

    private func getNotchWidth() -> CGFloat {
        guard let screen = NSScreen.main else { return 180 } // Default to 180 if it fails

        let screenWidth = screen.frame.width

        // Rough estimates based on Apple specs
        if screenWidth >= 3456 { // 16-inch MacBook Pro
            return 180
        } else if screenWidth >= 3024 { // 14-inch MacBook Pro
            return 160
        } else if screenWidth >= 2880 { // 15-inch MacBook Air
            return 170
        }

        // Default if we can't determine it
        return 180
    }

    @ViewBuilder
    private func renderBottomWidgets() -> some View {
        VStack {
            if animationState.isExpanded {
                /// Big Panel Widgets
                ZStack {
                    Color.black.opacity(1)
                        .clipShape(RoundedCornersShape(
                            topLeft: 10,
                            topRight: 10,
                            bottomLeft: 10,
                            bottomRight: 10
                        ))

                    HStack {
                        ForEach(bigWidgetStore.widgets.indices, id: \.self) { index in
                            let widgetEntry = bigWidgetStore.widgets[index]
                            if widgetEntry.isVisible {
                                widgetEntry.widget.swiftUIView
                                    .padding(.horizontal, 2)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .clipped()
        .animation(
            .easeInOut(duration: animationState.isExpanded ? 0.3 : 0.1),
            value: animationState.isExpanded
        )
    }

    @ViewBuilder
    private func renderTopRow() -> some View {
        HStack(spacing: 0) {
            // Left Widgets
            ZStack(alignment: .trailing) {
                HStack(spacing: 0) {
                    ForEach(widgetStore.leftWidgetsShown.indices, id: \.self) { index in
                        let widgetEntry = widgetStore.leftWidgetsShown[index]
                        if widgetEntry.isVisible {
                            widgetEntry.widget.swiftUIView
                                .padding(.top, 2)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            Spacer()
                .frame(width: getNotchWidth())
                .padding([.trailing, .leading], paddingWidth)
            // Right Widgets
            ZStack(alignment: .leading) {
                if !isHovering {
                    HStack(spacing: 0) {
                        ForEach(widgetStore.rightWidgetsShown.indices, id: \.self) { index in
                            let widgetEntry = widgetStore.rightWidgetsShown[index]
                            if widgetEntry.isVisible {
                                widgetEntry.widget.swiftUIView
                            }
                        }
                    }
                } else {
                    HStack(spacing: 0) {
                        //// If the widget is playing show pause
                        if animationState.songText != "No Song Playing" {
                            Button(action: AudioManager.shared.togglePlayPause ) {
                                Image(systemName: "pause.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 17, height: 15)
                                    .foregroundColor(Color(nsColor: animationState.playingColor))
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 23)
                        }
                        /// if the widget is not playing show play
                        else {
                            Button(action: AudioManager.shared.togglePlayPause ) {
                                Image(systemName: "play.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 17, height: 15)
                                    .foregroundColor(Color(nsColor: animationState.playingColor))
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 23)
                        }
                    }
                }
            }
                .onHover { hover in
                    if animationState.bottomSectionHeight == 0 {
                        isHovering = hover
                    } else {
                        isHovering = false
                    }
                }
        }
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity, maxHeight: UIManager.shared.getNotchHeight(), alignment: .top)
        // .border(Color.white, width: 0.5)
        .padding(.top, animationState.isExpanded ? 10 : 0)
    }
}
