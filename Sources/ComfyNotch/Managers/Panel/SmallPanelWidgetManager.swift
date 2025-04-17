import AppKit
import SwiftUI
import Combine
import MetalKit

/**
 * SmallPanelWidgetStore manages the widgets displayed in the notch panel area.
 * It handles the organization and visibility state of widgets, separating them into
 * left and right aligned sections.
 *
 * The store maintains four arrays:
 * - leftWidgetsHidden: Widgets aligned to the left that are currently hidden
 * - leftWidgetsShown: Widgets aligned to the left that are currently visible
 * - rightWidgetsHidden: Widgets aligned to the right that are currently hidden
 * - rightWidgetsShown: Widgets aligned to the right that are currently visible
 */
class SmallPanelWidgetStore: PanelManager, ObservableObject {
    @Published var leftWidgetsHidden: [WidgetEntry] = []
    @Published var leftWidgetsShown: [WidgetEntry] = []
    @Published var rightWidgetsHidden: [WidgetEntry] = []
    @Published var rightWidgetsShown: [WidgetEntry] = []

    /**
     * Adds a new widget to the appropriate hidden array based on its alignment.
     * If no alignment is specified, the widget defaults to left alignment.
     *
     * - Parameter widget: The Widget to be added
     */
    func addWidget(_ widget: Widget) {
        let widgetEntry = WidgetEntry(widget: widget, isVisible: false)

        if let alignment = widget.alignment {
            switch alignment {
            case .left:
                leftWidgetsHidden.append(widgetEntry)
            case .right:
                rightWidgetsHidden.append(widgetEntry)
            }
        } else {
            leftWidgetsHidden.append(widgetEntry)
        }
    }

    /**
     * Hides a widget by moving it from the shown array to the hidden array.
     * The widget's visibility state is updated to false.
     *
     * - Parameter name: The name of the widget to hide
     */
    func hideWidget(named name: String) {
        if let index = leftWidgetsShown.firstIndex(where: { $0.widget.name == name }) {
            leftWidgetsShown[index].isVisible = false
            let widgetEntry = leftWidgetsShown.remove(at: index)
            leftWidgetsHidden.append(widgetEntry)
        }
        if let index = rightWidgetsShown.firstIndex(where: { $0.widget.name == name }) {
            rightWidgetsShown[index].isVisible = false
            let widgetEntry = rightWidgetsShown.remove(at: index)
            rightWidgetsHidden.append(widgetEntry)
        }
    }

    /**
     * Shows a widget by moving it from the hidden array to the shown array.
     * The widget's visibility state is updated to true.
     *
     * - Parameter name: The name of the widget to show
     */
    func showWidget(named name: String) {
        // Show from the hidden list if it exists
        if let index = leftWidgetsHidden.firstIndex(where: { $0.widget.name == name }) {
            leftWidgetsHidden[index].isVisible = true
            let widgetEntry = leftWidgetsHidden.remove(at: index)
            leftWidgetsShown.append(widgetEntry)
        }
        if let index = rightWidgetsHidden.firstIndex(where: { $0.widget.name == name }) {
            rightWidgetsHidden[index].isVisible = true
            let widgetEntry = rightWidgetsHidden.remove(at: index)
            rightWidgetsShown.append(widgetEntry)
        }
    }

    /**
     * Removes a widget from the store completely.
     * Currently not implemented.
     *
     * - Parameter name: The name of the widget to remove
     */
    func removeWidget(named name: String) {
        // No Implementation Needed
    }

    /**
     * Removes all widgets from the store.
     * Currently not implemented.
     */
    func clearWidgets() {
        // No Implementation Needed
    }
}

class PanelAnimationState: ObservableObject {
    static let shared = PanelAnimationState()

    @Published var isExpanded: Bool = false
    @Published var bottomSectionHeight: CGFloat = 0
    @Published var songText: String = AudioManager.shared.currentSongText
    @Published var playingColor: NSColor = AudioManager.shared.dominantColor
    
    
    @Published var isBorderGlowing: Bool = false
    
    public func toggleBorderGlow() {
        isBorderGlowing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.isBorderGlowing = false
        }
    }
    
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

struct SmallPanelWidgetManager: View {

    @EnvironmentObject var widgetStore: SmallPanelWidgetStore
    @EnvironmentObject var priorityStore: BigPanelWidgetStore

    @ObservedObject var animationState = PanelAnimationState.shared
    @State private var isHovering: Bool = false

    private var paddingWidth: CGFloat = 20
    private var contentInset: CGFloat = 40

    var body: some View {
        ZStack {
            
            GeometryReader { geo in
                MetalBackgroundView(
                    shade: $animationState.playingColor,
                    pulse: $animationState.isBorderGlowing
                )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .allowsHitTesting(false)
                // Image("noise")
                //     .resizable()
                //     .scaledToFill()
                //     .opacity(0.05)
                //     .blendMode(.overlay)
            }
            
            if animationState.isExpanded {
                Color.clear  // let the Metal / noise show through
                    .clipShape(RoundedCornersShape(
                        topLeft: 0, topRight: 0,
                        bottomLeft: 20, bottomRight: 20
                    ))
            } else {
                Color.black.opacity(1)
                    .clipShape(RoundedCornersShape(
                        topLeft: 0, topRight: 0,
                        bottomLeft: 20, bottomRight: 20
                    ))
            }
            
            
            VStack(spacing: 0) {
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
                        if animationState.isExpanded {
                            isHovering = hover
                        } else {
                            isHovering = false
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)

                VStack {
                    /**
                     * This is the priority store section (IN PROGRESS)
                    */
                    if animationState.isExpanded {
                        // show the last item in the priority store
                        if let top = priorityStore.widgets.last(where: { $0.isVisible }) {
                            top.widget.swiftUIView
                        }
                        // Text(animationState.songText)
                        //     .font(.system(size: 16, weight: .bold))
                        //     .foregroundStyle(Color(nsColor: animationState.playingColor))
                        //     .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(height: animationState.bottomSectionHeight)
                .clipped()
                .animation(
                            .easeInOut(duration: animationState.isExpanded ? 0.3 : 0.1),
                            value: animationState.isExpanded
                        )

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedCornersShape(
                        topLeft: 0,
                        topRight: 0,
                        bottomLeft: 20,
                        bottomRight: 20
                 ))
        .mask(
            RoundedCornersShape(
                topLeft: 0,
                topRight: 0,
                bottomLeft: 20,
                bottomRight: 20
            )
        )
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
}

/// Preview is a bit messed up but it shows how it would look
/// In a real scenario
struct SmallPanelWidgetManager_Previews: PreviewProvider {
  static var smallStore: SmallPanelWidgetStore = {
    let store = SmallPanelWidgetStore()
    let album      = AlbumWidgetView(model: .init())
    let movingDots = MovingDotsView(model: .init())
    let settings   = SettingsButtonView(model: .init())
    // add & show each one:
    store.addWidget(album)
    store.showWidget(named: album.name)
    
    store.addWidget(movingDots)
    store.showWidget(named: movingDots.name)
    
    store.addWidget(settings)
    store.showWidget(named: settings.name)
    return store
  }()

  static var priorityStore: BigPanelWidgetStore = {
    let store = BigPanelWidgetStore()
    let current = CurrentSongWidget(
      model: MusicPlayerWidgetModel(),
      movingDotsModel: MovingDotsViewModel()
    )
    store.addWidget(current)
    store.showWidget(named: current.name)
    return store
  }()

  static var previews: some View {
    // Force expanded + give it some height
    let state = PanelAnimationState.shared
    state.isExpanded = true
    state.bottomSectionHeight = 40

    return SmallPanelWidgetManager()
      .environmentObject(smallStore)
      .environmentObject(priorityStore)
      .frame(width: 400, height: 80)
      .previewLayout(.sizeThatFits)
  }
}

#Preview {
  // 1) prepare stores
  let smallStore = SmallPanelWidgetStore()
  let album      = AlbumWidgetView(model: .init())
  smallStore.addWidget(album); smallStore.showWidget(named: album.name)
  // …add + show your other widgets…

  let priorityStore = BigPanelWidgetStore()
  let current = CurrentSongWidget(
    model: MusicPlayerWidgetModel(),
    movingDotsModel: MovingDotsViewModel()
  )
  priorityStore.addWidget(current)
  priorityStore.showWidget(named: current.name)

  // 2) expand panel
  let state = PanelAnimationState.shared
  state.isExpanded = true
  state.bottomSectionHeight = 40

  // 3) return your single View
  return SmallPanelWidgetManager()
    .environmentObject(smallStore)
    .environmentObject(priorityStore)
    .frame(width: 400, height: 80)
}


