import AppKit


class SmallPanelWidgetManager: WidgetManager {

    // This is what holds all of the widgets inside the small panel
    private var stackView : NSStackView = NSStackView()
    private var leftStackView : NSStackView = NSStackView()
    private var rightStackView : NSStackView = NSStackView()

    override init() {
        super.init()

        // This is what the contentView holds
        stackView.orientation = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .centerY
        stackView.spacing = 10

        
        // the stackView will hold these 2 values
        leftStackView.orientation = .horizontal
        leftStackView.distribution = .fill
        leftStackView.alignment = .centerY
        leftStackView.spacing = 10

        rightStackView.orientation = .horizontal
        rightStackView.distribution = .fill
        rightStackView.alignment = .centerY
        rightStackView.spacing = 10


        // the the left and right to the stackView
        stackView.addArrangedSubview(leftStackView)
        stackView.addArrangedSubview(getSpacer()) // Spacer
        stackView.addArrangedSubview(rightStackView)
    }

    /** 
     *
     *  This function gets a NSView with the width of the notch
     *
     */
    private func getSpacer() -> NSView {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        let notchWidth = self.getNotchWidth()
        NSLayoutConstraint.activate([
            spacer.widthAnchor.constraint(equalToConstant: notchWidth)
        ])

        return spacer
    }

    /**
     *
     *  we attach our stackView to the panelContentView
     *  this creates a hierarchy of NSPanel -> panelContentView -> stackView -> Widgets
     *
     */
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

    /**
     *
     *  This function will add the widget to either the left or the right
     *  stackView depending on the alignment of the widget, if no alignment
     *  is set, it will default to the left stackView
     *
     */
    override func addWidget(_ widget: Widget) {
        widgets.append(widget)
        // Handle Alignment
        if let alignment = widget.alignment {
            switch alignment {
                case .left:
                    leftStackView.addArrangedSubview(widget.view)
                case .right:
                    rightStackView.addArrangedSubview(widget.view)
            }
        } else {
            // Default to left alignment if no specific alignment is set
            leftStackView.addArrangedSubview(widget.view)
        }

        widget.view.setContentHuggingPriority(.defaultLow, 
                                              for: .horizontal)
        widget.view.setContentCompressionResistancePriority(.defaultLow, 
                                                            for: .horizontal)
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

    private func getNotchWidth() -> CGFloat {
        if let screen = NSScreen.main {
            let safeAreaInsets = screen.safeAreaInsets
            return safeAreaInsets.left + safeAreaInsets.right
        }
        return 0
    }
}