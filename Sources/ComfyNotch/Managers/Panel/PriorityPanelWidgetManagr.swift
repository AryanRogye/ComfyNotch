import Foundation

/*
 *  PriorityPanelWidgetStore is a implementation of the PanelManager protocol,
 *  the items inside will live inside the smallPanel, which is wrapped around the notch
 *  This "PriorityPanel" will replace current implimentations of the hover handler and how
 *  it shows the current song name. we will add onto this and add more logic
 *
 *  The goal of the priority panel is to show the most important widgets first
 *  how this would work is for whatever item is inside the priority panel itll show what
 *  was added to it
*/
class PriorityPanelWidgetStore: PanelManager, ObservableObject {

    @Published var widgets: [WidgetEntry] = []

    /// Adds a widget to the priority panel "store"
    func addWidget(_ widget: any Widget) {
        let widgetEntry = WidgetEntry(widget: widget, isVisible: false)
        widgets.append(widgetEntry)
    }

    /// Changes the visibility of a widget
    func hideWidget(named name: String) {
        if let index = widgets.firstIndex(where: { $0.widget.name == name }) {
            widgets[index].isVisible = false // Make the widget invisible
        }
    }

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

    func removeWidget(named name: String) {

    }

    func clearWidgets() {

    }
}
