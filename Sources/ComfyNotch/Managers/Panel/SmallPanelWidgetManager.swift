import AppKit
import SwiftUI

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

struct SmallPanelWidgetManager: View {

    @EnvironmentObject var widgetStore: SmallPanelWidgetStore

    private var paddingWidth: CGFloat = 20
    private var contentInset: CGFloat = 40

    var body: some View {
        ZStack {
            Color.black.opacity(1)
                .clipShape(RoundedCornersShape(topLeft: 0, 
                                               topRight: 0, 
                                               bottomLeft: 20, 
                                               bottomRight: 20))
            HStack(spacing: 0) {
                // Left Widgets
                ZStack(alignment: .trailing) {
                    HStack(spacing: 0) {
                        ForEach(widgetStore.leftWidgetsShown.indices, id: \.self) { index in
                            let widgetEntry = widgetStore.leftWidgetsShown[index]
                            if widgetEntry.isVisible {
                                widgetEntry.widget.swiftUIView
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
                    HStack(spacing: 0) {
                        ForEach(widgetStore.rightWidgetsShown.indices, id: \.self) { index in
                            let widgetEntry = widgetStore.rightWidgetsShown[index]
                            if widgetEntry.isVisible {
                                widgetEntry.widget.swiftUIView
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
