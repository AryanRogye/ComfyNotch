import AppKit


class SettingsWidget : NSObject, Widget {

    var name: String = "Settings"
    var view: NSView

    var settingsButton: NSButton
    private var _alignment: WidgetAlignment = .right


    var alignment: WidgetAlignment? {
        get { return _alignment }
        set { 
            if let newValue = newValue {
                _alignment = newValue
                print("Setting alignment to: \(newValue)")
            }
        }
    }

    override init () {
        view = NSView()
        view.isHidden = true
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        view.layer?.borderWidth = 1.5
        view.layer?.borderColor = NSColor.darkGray.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false


        settingsButton = NSButton()
        super.init()

        self.setupInternalConstraints()
    }

    func setupInternalConstraints() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        view.layer?.borderWidth = 1.5
        view.layer?.borderColor = NSColor.darkGray.cgColor

        settingsButton = createStyledButton(symbolName: "gear", action: #selector(openSettings))

        view.addSubview(settingsButton)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            settingsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            settingsButton.widthAnchor.constraint(equalToConstant: 20),
            settingsButton.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    @objc func openSettings() {
        print("Opening settings")
    }

    private func createStyledButton(symbolName: String, action: Selector) -> NSButton {
        let button = NSButton()
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)

        if image == nil {
            print("Error: Failed to load system symbol '\(symbolName)'")
        }

        button.image = image
        button.target = self
        button.action = action
        button.wantsLayer = true
        button.isBordered = false
        button.layer?.cornerRadius = 8
        button.contentTintColor = .white // Make sure tint color is visible
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.isEnabled = true
        button.setButtonType(.momentaryPushIn)

        return button
    }

    func update() {

    }

    func show() {
        view.isHidden = false
    }

    func hide() {
        view.isHidden = true
    }

}