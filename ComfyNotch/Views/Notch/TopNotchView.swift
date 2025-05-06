import SwiftUI

enum TopNotchViewStates {
    case noMusicPlaying
    case musicPlaying
    case openedNotch
}

struct TopNotchView: View {

    @EnvironmentObject var widgetStore: CompactWidgetsStore
    @ObservedObject var animationState = PanelAnimationState.shared

    @State private var isHovering: Bool = false/// Hovering for Pause or Play
    private var paddingWidth: CGFloat = 20

    var body: some View {
        HStack(spacing: 0) {
            // Left Widgets
            ZStack(alignment: .leading) {
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
                .frame(width: PanelAnimationState.shared.isExpanded ? 450 : getNotchWidth())
                .padding([.trailing, .leading], paddingWidth)
            
//            Spacer()
//                .frame(width: calculatedSpacerWidth)
//                .padding(.horizontal, animationState.currentPanelWidth >= 320 ? paddingWidth : 0)
//                .animation(.interpolatingSpring(stiffness: 180, damping: 18), value: animationState.currentPanelWidth)
            
//            Spacer()
//                .frame(width: animationState.currentPanelWidth >= 320
//                       ? (animationState.isExpanded ? 450 : getNotchWidth())
//                       : 0)
//                .padding([.trailing, .leading], animationState.currentPanelWidth >= 320 ? paddingWidth : 0)
//                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: animationState.currentPanelWidth)
            
            // Right Widgets
            ZStack(alignment: .leading) {
                if !isHovering {
                    HStack(spacing: 0) {
                        ForEach(widgetStore.rightWidgetsShown.indices, id: \.self) { index in
                            let widgetEntry = widgetStore.rightWidgetsShown[index]
                            if widgetEntry.isVisible {
                                widgetEntry.widget.swiftUIView
                                    .opacity(isHovering ? 0 : 1)
                            }
                        }
                    }
                } else {
                    HStack(spacing: 0) {
                        //// If the widget is playing show pause
                        if animationState.musicModel.nowPlayingInfo.trackName != "No Song Playing" {
                            Button(action: AudioManager.shared.togglePlayPause ) {
                                Image(systemName: "pause.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 17, height: 15)
                                    .foregroundColor(Color(nsColor: animationState.musicModel.nowPlayingInfo.dominantColor))
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
                                    .foregroundColor(Color(nsColor: animationState.musicModel.nowPlayingInfo.dominantColor))
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
        .padding(.top,
                 animationState.isExpanded
                 
                 ? (animationState.currentPanelState == .file_tray
                        /// This is to keep the Top Row Steady, if the filetray is showing
                        ? -1
                        /// This is when the fileTray is not showing and its just the widgets
                        /// should have a -1 padding height
                        /// Note: I realizes that having both being the same was the best in this case
                        /// Old Value used to be 10, so if soemthing is fucked change it back
                        : -1
                 )
                 /// This is when the panel is closed and we're just looking at it
                 : 1
        )
    }

    func getNotchWidth() -> CGFloat {
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
}
