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


class BigPanelWidgetManager: WidgetManager {
    override func layoutWidgets() {
        guard let panelContentView = panelContentView else { return }

        // Remove all existing constraints first
        panelContentView.constraints.forEach { panelContentView.removeConstraint($0) }

        // Limit the number of widgets displayed
        let visibleWidgets = widgets.prefix(3) // Only take the first 3 widgets
        
        let totalWidth: CGFloat = 650 // The total width of the big_panel
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

class SmallPanelWidgetManager: WidgetManager {
    override func addWidget(_ widget: Widget) {
        guard let panelContentView = panelContentView else { return }

        // Print debug info
        
        widget.view.translatesAutoresizingMaskIntoConstraints = false
        panelContentView.addSubview(widget.view)
        widgets.append(widget)
        
        // Don't apply constraints here, just add to the array
        // We'll apply all constraints in layoutWidgets
    }
    
    override func layoutWidgets() {
        guard let panelContentView = panelContentView else { return }
        
        
        // Remove ALL existing widget constraints
        for subview in panelContentView.subviews {
            for constraint in panelContentView.constraints {
                if let firstView = constraint.firstItem as? NSView, firstView == subview {
                    panelContentView.removeConstraint(constraint)
                }
                if let secondView = constraint.secondItem as? NSView, secondView == subview {
                    panelContentView.removeConstraint(constraint)
                }
            }
        }
        
        var leftX: CGFloat = 10
        var rightX: CGFloat = 10
        
        // Separate widgets by alignment
        let leftWidgets = widgets.filter { $0.alignment != .right }
        let rightWidgets = widgets.filter { $0.alignment == .right }
        
        
        // Layout left widgets first
        for widget in leftWidgets {
            NSLayoutConstraint.activate([
                widget.view.leadingAnchor.constraint(equalTo: panelContentView.leadingAnchor, constant: leftX),
                widget.view.centerYAnchor.constraint(equalTo: panelContentView.centerYAnchor),
                widget.view.widthAnchor.constraint(equalToConstant: 30),
                widget.view.heightAnchor.constraint(equalToConstant: 30)
            ])
            leftX += 30 + 10
        }
        
        // Then layout right widgets
        for widget in rightWidgets {
            NSLayoutConstraint.activate([
                widget.view.trailingAnchor.constraint(equalTo: panelContentView.trailingAnchor, constant: -rightX),
                widget.view.centerYAnchor.constraint(equalTo: panelContentView.centerYAnchor),
                widget.view.widthAnchor.constraint(equalToConstant: 30),
                widget.view.heightAnchor.constraint(equalToConstant: 30)
            ])
            rightX += 30 + 10
        }
        
        // Force layout update
        panelContentView.layoutSubtreeIfNeeded()
    }
    
    // Helper method to log all constraints
    func logAllConstraints() {
        guard let panelContentView = panelContentView else { return }
        print("=== All Constraints ===")
        for (index, constraint) in panelContentView.constraints.enumerated() {
            print("Constraint \(index): \(constraint)")
        }
        print("======================")
    }
}