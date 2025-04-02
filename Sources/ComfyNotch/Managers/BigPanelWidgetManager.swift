import AppKit

class BigPanelWidgetManager: WidgetManager {

    private var stackView: NSStackView = NSStackView()


    override init() {
        super.init()

        stackView.orientation = .horizontal
        // This should be equally filled
        stackView.distribution = .fillEqually
        stackView.alignment = .top
        stackView.alignment = .centerY
    }

    override func setPanelContentView(_ view: NSView) {
        super.setPanelContentView(view)
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

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

        widget.view.setContentHuggingPriority(.defaultLow, for: .vertical)
        widget.view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        stackView.layoutSubtreeIfNeeded()
    }

    override func layoutWidgets() {
        // Force layout update
        stackView.layoutSubtreeIfNeeded()
    }
}