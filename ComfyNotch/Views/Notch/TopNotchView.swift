import SwiftUI

struct TopNotchView: View {
    
    @EnvironmentObject var widgetStore: CompactWidgetsStore
    @ObservedObject var notchStateManager = NotchStateManager.shared
    @ObservedObject var settings: SettingsModel = .shared
    @ObservedObject var musicModel: MusicPlayerWidgetModel = .shared
    @ObservedObject var uiManager: UIManager = .shared
    
    @State private var isHovering: Bool = false /// Hovering for Pause or Play
    private let paddingWidth: CGFloat = 20
    
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
//                if uiManager.panelState == .closed && musicModel.nowPlayingInfo.isPlaying {
                    leftWidgets
//                } else if uiManager.panelState == .open {
//                    leftWidgets
//                }
            }
            .padding(.leading, leadingPadding)
//            .onReceive(musicModel.nowPlayingInfo.$isPlaying) { isPlaying in
//                if uiManager.panelState == .closed && isPlaying {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                        ScrollHandler.shared.expandWidth()
//                    }
//                } else if uiManager.panelState == .closed && !isPlaying {
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                        ScrollHandler.shared.reduceWidth()
//                    }
//                }
//            }
            
            Spacer()
            
            //MARK: - Right Widgets
            HStack {
//                if uiManager.panelState == .closed && musicModel.nowPlayingInfo.isPlaying {
                    rightWidgets
//                } else if uiManager.panelState == .open {
//                    rightWidgets
//                }
            }
            .padding(.trailing, trailingPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: UIManager.shared.getNotchHeight(), alignment: .top)
    }
    
    // MARK: - Left Widget
    private var leftWidgets: some View {
        ZStack(alignment: .leading) {
            widgetStore.leftWidgets
        }
        .onHover { hover in
            notchStateManager.hoverHandler.isHoveringOverLeft =
            hover &&
            MusicPlayerWidgetModel.shared.nowPlayingInfo.isPlaying &&
            settings.hoverTargetMode == .album &&
            notchStateManager.bottomSectionHeight == 0
        }
    }
    
    // MARK: - Right Widget
    private var rightWidgets: some View {
        ZStack(alignment: .trailing) {
            if isHovering {
                playPause
            } else {
                widgetStore.rightWidgets
                    .opacity(isHovering ? 0 : 1)
            }
        }
        // NOTE: We sync both local isHovering and global hoverHandler here.
        // This allows NSEvent-based monitoring to check hover state globally,
        // while preserving local animation performance.
        //
        // See ComfyNotchView.swift: startMonitoring() for usage of
        // `animationState.hoverHandler.isHoveringOverPlayPause`.
        .onHover { hover in
            if notchStateManager.bottomSectionHeight == 0 {
                withAnimation(.easeInOut(duration: 0.15)) {
                    notchStateManager.hoverHandler.isHoveringOverPlayPause = hover
                    isHovering = hover
                }
            } else {
                notchStateManager.hoverHandler.isHoveringOverPlayPause = false
                isHovering = false
            }
        }
    }
    
    // MARK: - Play Pause Button
    private var playPauseFont: CGFloat = 14
    private var playPauseTrailing: CGFloat = 8
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
