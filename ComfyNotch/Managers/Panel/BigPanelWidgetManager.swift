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
        print("🗑️ Clearing all widgets from the big panel.")
        widgets.removeAll()
    }
}
