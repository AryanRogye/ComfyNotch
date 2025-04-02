import AppKit

class WidgetManager {
    static let shared = WidgetManager()
    
    // For how we store the apps widgets
    var widgets: [Widget] = []
    var panelContentView: NSView? = nil

    init() {}

    func setPanelContentView(_ view: NSView) {
        panelContentView = view
    }

    func addWidget(_ widget: Widget) {
        guard let panelContentView = panelContentView else {
            print("Panel content view not set. Use `setPanelContentView()` before adding widgets.")
            return
        }

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
        
    }

    func updateWidgets() {
        for widget in widgets {
            widget.update()
        }
    }
}