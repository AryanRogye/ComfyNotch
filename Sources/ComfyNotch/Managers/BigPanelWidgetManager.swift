import AppKit

class BigPanelWidgetManager: WidgetManager {
    override func layoutWidgets() {
        guard let panelContentView = panelContentView else { return }

        // Remove all existing constraints first
        panelContentView.constraints.forEach { panelContentView.removeConstraint($0) }

        // Limit the number of widgets displayed
        let visibleWidgets = widgets.prefix(3) // Only take the first 3 widgets
        
        let totalWidth: CGFloat = 700 // The total width of the big_panel
        let widgetWidth = totalWidth / CGFloat(visibleWidgets.count) // Divide width evenly
        let widgetHeight: CGFloat = 100

        var currentX: CGFloat = 0

        // Calculate total width of the visible widgets
        let totalWidgetWidth = widgetWidth * CGFloat(visibleWidgets.count)

        // Calculate the padding needed to center the widgets
        let paddingX = (totalWidth - totalWidgetWidth) / 2

        for widget in visibleWidgets {
            let widgetView = widget.view
            widgetView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                widgetView.leadingAnchor.constraint(equalTo: panelContentView.leadingAnchor, constant: currentX + paddingX), // Apply padding to center
                widgetView.topAnchor.constraint(equalTo: panelContentView.topAnchor),
                widgetView.widthAnchor.constraint(equalToConstant: widgetWidth),
                widgetView.heightAnchor.constraint(equalToConstant: widgetHeight)
            ])

            currentX += widgetWidth
        }

        // Force layout update
        panelContentView.layoutSubtreeIfNeeded()
    }
}