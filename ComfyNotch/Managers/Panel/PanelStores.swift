import AppKit
import SwiftUI

/**
 * `ExpandedWidgetsStore` is a class that manages a collection of widgets for a "big panel" UI component.
 * It provides functionality to add, remove, show, hide, and clear widgets, while maintaining their visibility state.
 * The class is designed to work with SwiftUI and uses the `@Published` property wrapper to notify observers of changes.
 */
class ExpandedWidgetsStore: PanelManager, ObservableObject {
    @Published var widgets: [WidgetEntry] = []

    /// Adds a widget to the big panel "store"
    /// -   widget: The widget to add
    func addWidget(_ widget: Widget) {
        let widgetEntry = WidgetEntry(widget: widget, isVisible: false)
        // if widgets.count >= 4 {
        //     return
        // }
        widgets.append(widgetEntry)
    }

    /// Removes a widget from the big panel "store"
    /// This should be used by anything related to the "settings"
    /// -   name: name of the widget to remove
    func removeWidget(named name: String) {
        if widgets.isEmpty {
            return
        }
        if let index = widgets.firstIndex(where: { $0.widget.name == name }) {
            widgets.remove(at: index)
        }
    }

    /**
      *  Hides a widget from the big panel "store"
      *  This is really the best way to "hide" or not show the widget
      *  when the panel is closed
      *  -  name: name of the widget to hide
    ***/
    func hideWidget(named name: String) {
        if let index = widgets.firstIndex(where: { $0.widget.name == name }) {
            widgets[index].isVisible = false
        }
    }

    /**
      *  Shows a widget from the big panel "store"
      *  This changes the visibility of the widget
      *  when the panel is open
      *  -  name: name of the widget to show
    ***/
    func showWidget(named name: String) {
        // Show from the hidden list if it exists
        if let index = widgets.firstIndex(where: { $0.widget.name == name }) {
            widgets[index].isVisible = true // Make the widget visible
            widgets[index] = WidgetEntry(
                widget: widgets[index].widget,
                isVisible: true
            )
        }
    }

    /// Function to remove all widgets from the big panel
    func clearWidgets() {
        debugLog("🗑️ Clearing all widgets from the big panel.")
        widgets.removeAll()
    }
}


/**
 * CompactWidgetsStore manages the widgets displayed in the notch panel area.
 * It handles the organization and visibility state of widgets, separating them into
 * left and right aligned sections.
 *
 * The store maintains four arrays:
 * - leftWidgetsHidden: Widgets aligned to the left that are currently hidden
 * - leftWidgetsShown: Widgets aligned to the left that are currently visible
 * - rightWidgetsHidden: Widgets aligned to the right that are currently hidden
 * - rightWidgetsShown: Widgets aligned to the right that are currently visible
 */
class CompactWidgetsStore: PanelManager, ObservableObject {
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
