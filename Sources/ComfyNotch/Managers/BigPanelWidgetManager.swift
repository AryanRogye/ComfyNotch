import AppKit
import SwiftUI

class BigPanelWidgetStore: ObservableObject {
    @Published var widgets : [WidgetEntry] = []

    func addWidget(_ widget: SwiftUIWidget) {
        print("Adding widget: \(widget.name)")
        let widgetEntry = WidgetEntry(widget: widget, isVisible: false)
        if widgets.count >= 3 {
            print("Cannot add more than 3 widgets to the big panel.")
            return
        }
        widgets.append(widgetEntry)
    }

    func removeWidget(named name: String) {
        if let index = widgets.firstIndex(where: { $0.widget.name == name }) {
            widgets.remove(at: index)
        }
    }

    func hideWidget(named name: String) {
        print("Hiding widget: \(name)")
        if let index = widgets.firstIndex(where: { $0.widget.name == name }) {
            widgets[index].isVisible = false
        }
    }

    func showWidget(named name: String) {
        print("Showing widget: \(name)")
        // Show from the hidden list if it exists
        if let index = widgets.firstIndex(where: { $0.widget.name == name }) {
            widgets[index].isVisible = true
        }
    }
}

struct BigPanelWidgetManager : View {
    @EnvironmentObject var widgetStore: BigPanelWidgetStore

    var body : some View {
        ZStack {
            Color.black.opacity(1)
                .clipShape(RoundedCornersShape(topLeft: 0, 
                                               topRight: 0, 
                                               bottomLeft: 20, 
                                               bottomRight: 20))
                HStack(spacing: 1) {
                    ForEach(widgetStore.widgets.indices, id: \.self) { index in
                        let widgetEntry = widgetStore.widgets[index]
                        if widgetEntry.isVisible {
                            widgetEntry.widget.swiftUIView
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(10)
                        }
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

class _BigPanelWidgetManager: WidgetManager {
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
