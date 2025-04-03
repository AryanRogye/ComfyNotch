import AppKit


class SmallPanelWidgetManager: WidgetManager {

    // This is what holds all of the widgets inside the small panel
    private var stackView : NSStackView = NSStackView()
    private var leftStackView : NSStackView = NSStackView()
    private var rightStackView : NSStackView = NSStackView()
    private var notchSpacer: NSView = NSView()


    private var paddingWidth: CGFloat = 5

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

        let leftPadding = createPaddingSpacer()
        let rightPadding = createPaddingSpacer()


        // the the left and right to the stackView
        stackView.addArrangedSubview(leftPadding)
        stackView.addArrangedSubview(leftStackView)
        notchSpacer = getSpacer()
        stackView.addArrangedSubview(notchSpacer) // Notch spacer
        stackView.addArrangedSubview(rightStackView)
        stackView.addArrangedSubview(rightPadding)
    }

    private func createPaddingSpacer() -> NSView {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            spacer.widthAnchor.constraint(equalToConstant: paddingWidth)
        ])
        return spacer
    }

    /** 
     *
     *  This function gets a NSView with the width of the notch
     *
     */
    private func getSpacer() -> NSView {
        let spacer = NSView()
        spacer.translatesAutoresizingMaskIntoConstraints = false

        // Ensure the spacer has a constant width
        let notchWidth = self.getNotchWidth() + 10
        NSLayoutConstraint.activate([
            spacer.widthAnchor.constraint(equalToConstant: notchWidth),
            spacer.heightAnchor.constraint(equalToConstant: 1) // Small height to ensure it's part of the layout
        ])
        
        spacer.wantsLayer = true
        // spacer.layer?.backgroundColor = NSColor.red.cgColor // Visualize the spacer for debugging

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
        guard let screen = NSScreen.main else { return 180 } // Default to 180 if it fails
    
        let screenWidth = screen.frame.width

        // Rough estimates based on Apple specs
        if screenWidth >= 3456 { // 16-inch MacBook Pro
            return 180
        } else if screenWidth >= 3024 { // 14-inch MacBook Pro
            return 160
        } else if screenWidth >= 2880 { // 15-inch MacBook Air
            return 170
        }

        // Default if we can't determine it
        return 180
    }
}