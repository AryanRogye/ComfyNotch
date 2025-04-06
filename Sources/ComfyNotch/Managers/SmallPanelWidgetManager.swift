import AppKit
import SwiftUI

struct WidgetEntry {
    var widget: SwiftUIWidget
    var isVisible: Bool
}

class PanelStore {

}

class SmallPanelWidgetStore: ObservableObject {
    @Published var leftWidgetsHidden: [WidgetEntry] = []
    @Published var leftWidgetsShown: [WidgetEntry] = []
    @Published var rightWidgetsHidden: [WidgetEntry] = []
    @Published var rightWidgetsShown: [WidgetEntry] = []

    func addWidget(_ widget: SwiftUIWidget) {
        let widgetEntry = WidgetEntry(widget: widget, isVisible: false)
        
        if let alignment = widget.alignment {
            switch alignment {
            case .left:
                leftWidgetsHidden.append(widgetEntry)
            case .right:
                rightWidgetsHidden.append(widgetEntry)
            }
        } else {
            leftWidgetsHidden.append(widgetEntry)
        }
    }

    func hideWidget(named name: String) {
        if let index = leftWidgetsShown.firstIndex(where: { $0.widget.name == name }) {
            leftWidgetsShown[index].isVisible = false
            let widgetEntry = leftWidgetsShown.remove(at: index)
            leftWidgetsHidden.append(widgetEntry)
        }
        
        if let index = rightWidgetsShown.firstIndex(where: { $0.widget.name == name }) {
            rightWidgetsShown[index].isVisible = false
            let widgetEntry = rightWidgetsShown.remove(at: index)
            rightWidgetsHidden.append(widgetEntry)
        }
    }

    func showWidget(named name: String) {
        // Show from the hidden list if it exists
        if let index = leftWidgetsHidden.firstIndex(where: { $0.widget.name == name }) {
            leftWidgetsHidden[index].isVisible = true
            let widgetEntry = leftWidgetsHidden.remove(at: index)
            leftWidgetsShown.append(widgetEntry)
        }
        
        if let index = rightWidgetsHidden.firstIndex(where: { $0.widget.name == name }) {
            rightWidgetsHidden[index].isVisible = true
            let widgetEntry = rightWidgetsHidden.remove(at: index)
            rightWidgetsShown.append(widgetEntry)
        }
    }
}

struct SmallPanelWidgetManager: View {

    @EnvironmentObject var widgetStore: SmallPanelWidgetStore

    private var paddingWidth: CGFloat = 20
    private var contentInset: CGFloat = 40

    var body: some View {
        ZStack {
            Color.black.opacity(1)
                .clipShape(RoundedCornersShape(topLeft: 0, 
                                               topRight: 0, 
                                               bottomLeft: 20, 
                                               bottomRight: 20))
            HStack(spacing: 0) {
                // Left Widgets
                ZStack(alignment: .trailing) {
                    HStack(spacing: 0) {
                        ForEach(widgetStore.leftWidgetsShown.indices, id: \.self) { index in
                            let widgetEntry = widgetStore.leftWidgetsShown[index]
                            if widgetEntry.isVisible {
                                widgetEntry.widget.swiftUIView
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                Spacer()
                    .frame(width: getNotchWidth())
                    .padding([.trailing, .leading], paddingWidth)

                // Right Widgets
                ZStack(alignment: .leading) {
                    HStack(spacing: 0) {
                        ForEach(widgetStore.rightWidgetsShown.indices, id: \.self) { index in
                            let widgetEntry = widgetStore.rightWidgetsShown[index]
                            if widgetEntry.isVisible {
                                widgetEntry.widget.swiftUIView
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // /** 
    //  *
    //  *  This function gets a NSView with the width of the notch
    //  *
    //  */
    // private func getSpacer() -> NSView {
    //     let spacer = NSView()
    //     spacer.translatesAutoresizingMaskIntoConstraints = false

    //     // Ensure the spacer has a constant width
    //     let notchWidth = self.getNotchWidth() + 10
    //     NSLayoutConstraint.activate([
    //         spacer.widthAnchor.constraint(equalToConstant: notchWidth),
    //         spacer.heightAnchor.constraint(equalToConstant: 1) // Small height to ensure it's part of the layout
    //     ])
        
    //     spacer.wantsLayer = true
    //     // spacer.layer?.backgroundColor = NSColor.red.cgColor // Visualize the spacer for debugging

    //     return spacer
    // }

    // /**
    //  *
    //  *  we attach our stackView to the panelContentView
    //  *  this creates a hierarchy of NSPanel -> panelContentView -> stackView -> Widgets
    //  *
    //  */
    // override func setPanelContentView(_ view: NSView) {
    //     super.setPanelContentView(view)
    //     view.addSubview(stackView)
    //     stackView.translatesAutoresizingMaskIntoConstraints = false

    //     // Pinning stackView to the edges of the panelContentView
    //     // This is kinda like we just pasted the stackView to the panelContentView
    //     NSLayoutConstraint.activate([
    //         stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    //         stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    //         stackView.topAnchor.constraint(equalTo: view.topAnchor),
    //         stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    //     ])
    // }

    // /**
    //  *
    //  *  This function will add the widget to either the left or the right
    //  *  stackView depending on the alignment of the widget, if no alignment
    //  *  is set, it will default to the left stackView
    //  *
    //  */
    // func addWidget(_ widget: Widget) {
    //     widgets.append(widget)
    //     // Handle Alignment
    //     if let alignment = widget.alignment {
    //         switch alignment {
    //             case .left:
    //                 leftStackView.addArrangedSubview(widget.view)
    //             case .right:
    //                 rightStackView.addArrangedSubview(widget.view)
    //         }
    //     } else {
    //         // Default to left alignment if no specific alignment is set
    //         leftStackView.addArrangedSubview(widget.view)
    //     }

    //     widget.view.setContentHuggingPriority(.defaultLow, 
    //                                           for: .horizontal)
    //     widget.view.setContentCompressionResistancePriority(.defaultLow, 
    //                                                         for: .horizontal)
    // }
    
    // override func layoutWidgets() {
    //     // Force layout update
    //     stackView.layoutSubtreeIfNeeded()
    // }
    
    // // Helper method to log all constraints
    // func logAllConstraints() {
    //     guard let panelContentView = panelContentView else { return }
    //     print("=== All Constraints ===")
    //     for (index, constraint) in panelContentView.constraints.enumerated() {
    //         print("Constraint \(index): \(constraint)")
    //     }
    //     print("======================")
    // }

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
