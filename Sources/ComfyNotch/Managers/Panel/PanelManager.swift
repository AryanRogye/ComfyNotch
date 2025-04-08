import Foundation

/**
 * WidgetEntry represents a widget and its visibility state in the panel.
 * This struct is used to track both the widget itself and whether it's currently visible.
 *
 * Properties:
 * - widget: The Widget instance
 * - isVisible: Boolean flag indicating if the widget is currently visible
 */
struct WidgetEntry {
    var widget: Widget
    var isVisible: Bool
}

/**
 * PanelManager defines the core functionality for managing widgets in a panel.
 * This protocol provides the basic operations needed to handle widget lifecycle.
 *
 * Required methods:
 * - addWidget: Adds a new widget to the panel
 * - hideWidget: Hides a specific widget from view
 * - showWidget: Makes a specific widget visible
 * - removeWidget: Removes a widget completely from the panel
 * - clearWidgets: Removes all widgets from the panel
 */
protocol PanelManager {
    /**
     * Adds a new widget to the panel.
     * - Parameter widget: The Widget to be added
     */
    func addWidget(_ widget: Widget)
    
    /**
     * Hides a specific widget from view.
     * - Parameter name: The name of the widget to hide
     */
    func hideWidget(named name: String)
    
    /**
     * Makes a specific widget visible.
     * - Parameter name: The name of the widget to show
     */
    func showWidget(named name: String)
    
    /**
     * Removes a widget completely from the panel.
     * - Parameter name: The name of the widget to remove
     */
    func removeWidget(named name: String)
    
    /**
     * Removes all widgets from the panel.
     */
    func clearWidgets()
}