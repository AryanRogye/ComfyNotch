import AppKit

class WidgetManager {
    static let shared = WidgetManager()
    
    // For how we store the apps widgets
    private var widgets: [Widget] = []
    private var panelContentView: NSView? = nil

    private init() {}

    func setPanelContentView(_ view: NSView) {
        panelContentView = view
    }

    func addWidget(_ widget: Widget) {
        guard let panelContentView = panelContentView else {
            print("Panel content view not set. Use `setPanelContentView()` before adding widgets.")
            return
        }
        print("Added widget \(widget.name) to panel content view")

        // Add the widget's view to the panel content view
        panelContentView.addSubview(widget.view)
        widgets.append(widget)

        // Position the widget properly (for now, just stacking them vertically)
        layoutWidgets()
    }

    func removeWidget(_ widget: Widget) {
        widget.view.removeFromSuperview()
        if let index = widgets.firstIndex(where: { $0.name == widget.name }) {
            widgets.remove(at: index)
        }
        
        layoutWidgets()
    }

    func showWidgets() {
        for widget in widgets {
            widget.show()
        }
        layoutWidgets()
    }

    func hideWidgets() {
        for widget in widgets {
            widget.hide()
        }
    }

    func layoutWidgets() {
        guard let panelContentView = panelContentView else { return }

        var currentX: CGFloat = 0
        let widgetSpacing: CGFloat = 10

        for widget in widgets {
            widget.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                widget.view.leadingAnchor.constraint(equalTo: panelContentView.leadingAnchor, constant: currentX),
                widget.view.topAnchor.constraint(equalTo: panelContentView.topAnchor),
                widget.view.bottomAnchor.constraint(equalTo: panelContentView.bottomAnchor), // Fill vertically
                widget.view.widthAnchor.constraint(equalToConstant: 200) // Adjust width as needed
            ])
            currentX += 200 + widgetSpacing // Use the set width in the loop.
        }
    }

    func updateWidgets() {
        for widget in widgets {
            widget.update()
        }
    }
}
