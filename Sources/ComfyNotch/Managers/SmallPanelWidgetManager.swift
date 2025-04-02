import AppKit


class SmallPanelWidgetManager: WidgetManager {

    // This is what holds all of the widgets inside the small panel
    private var stackView : NSStackView = NSStackView()

    override init() {
        super.init()
        stackView.orientation = .horizontal
        // this makes sure that there is space between the widgets
        stackView.distribution = .gravityAreas
        stackView.alignment = .centerY
        stackView.spacing = 10
    }

    // we attach our stackView to the panelContentView
    // this creates a hierarchy of NSPanel -> panelContentView -> stackView -> Widgets
    override func setPanelContentView(_ view: NSView) {
        super.setPanelContentView(view)
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Pinning stackView to the edges of the panelContentView
        // This is kinda like we just pasted the stackView to the panelContentView
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override func addWidget(_ widget: Widget) {
        widgets.append(widget)
        stackView.addArrangedSubview(widget.view)
    }
    
    override func layoutWidgets() {
        // Force layout update
        stackView.layoutSubtreeIfNeeded()
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