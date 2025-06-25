import SwiftUI

enum TopNotchViewStates {
    case noMusicPlaying
    case musicPlaying
    case openedNotch
}

struct TopNotchView: View {
    
    @EnvironmentObject var widgetStore: CompactWidgetsStore
    @ObservedObject var animationState = PanelAnimationState.shared
    @ObservedObject var settings: SettingsModel = .shared
    @ObservedObject var musicModel: MusicPlayerWidgetModel = .shared
    
    @State private var isHovering: Bool = false /// Hovering for Pause or Play
    private var paddingWidth: CGFloat = 20
    
    private var leadingPadding: CGFloat {
        return 11
    }
    
    private var trailingPadding: CGFloat {
        return 11
    }
    
    var body: some View {
        HStack(spacing: 0) {
            //MARK: - Left Widgets
            HStack {
                leftWidgets
            }
            .padding(.leading, leadingPadding)
            
            Spacer()
            
            //MARK: - Right Widgets
            HStack {
                rightWidgets
            }
            .padding(.trailing, trailingPadding)
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
    
    // MARK: - Left Widget
    private var leftWidgets: some View {
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
        .onHover { hover in
            if settings.hoverTargetMode != .album { return }
            if animationState.bottomSectionHeight == 0 {
                animationState.hoverHandler.isHoveringOverLeft = hover
            } else {
                animationState.hoverHandler.isHoveringOverLeft = false
            }
        }
    }
    
    // MARK: - Right Widget
    private var rightWidgets: some View {
        ZStack(alignment: .leading) {
            if isHovering {
                playPause
            } else {
                HStack(spacing: 0) {
                    ForEach(widgetStore.rightWidgetsShown.indices, id: \.self) { index in
                        let widgetEntry = widgetStore.rightWidgetsShown[index]
                        if widgetEntry.isVisible {
                            widgetEntry.widget.swiftUIView
                                .opacity(isHovering ? 0 : 1)
                        }
                    }
                }
            }
        }
        .onHover { hover in
            if animationState.bottomSectionHeight == 0 {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hover
                }
            } else {
                isHovering = false
            }
        }
    }
    
    // MARK: - Play Pause Button
    private var playPauseFont: CGFloat = 14
    private var playPauseTrailing: CGFloat = 14
    private var playPauseTop: CGFloat = 4
    
    private var playPause: some View {
        HStack(spacing: 0) {
            let isPlaying = musicModel.nowPlayingInfo.isPlaying
            Button(action: AudioManager.shared.togglePlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: playPauseFont, weight: .medium)) // Native sizing
                    .foregroundStyle(Color(nsColor: musicModel.nowPlayingInfo.dominantColor))
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
            }
            .buttonStyle(.borderless)
            .padding(.trailing, playPauseTrailing)
            .padding(.top, playPauseTop)
            .contentShape(Rectangle()) // Better hitbox
        }
    }
    
    // MARK: - Internals
    private func getNotchWidth() -> CGFloat {
        guard let screen = DisplayManager.shared.selectedScreen else { return 180 } // Default to 180 if it fails
        
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
