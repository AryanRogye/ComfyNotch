import SwiftUI

struct HomeNotchView: View {
    
    @EnvironmentObject var bigWidgetStore: ExpandedWidgetsStore
    @ObservedObject var uiManager = UIManager.shared
    @ObservedObject var settingsModel = SettingsModel.shared
    
    @State private var givenSpace: GivenWidgetSpace = GivenWidgetSpace(w: 0, h: 0)

    var body: some View {
        HStack(spacing: 0) {
            if uiManager.panelState == .open {
                /// Big Panel Widgets
                let lastVisibleIndex = bigWidgetStore.widgets.lastIndex(where: { $0.isVisible })
                
                ForEach(bigWidgetStore.widgets.indices, id: \.self) { index in
                    let widgetEntry = bigWidgetStore.widgets[index]
                    if widgetEntry.isVisible {
                        HStack(spacing: 0) {
                            widgetEntry.widget.swiftUIView
                        }
                    }
                }
            }
        }
        .frame(width: givenSpace.w, height: givenSpace.h)
        .onAppear {
            givenSpace = uiManager.expandedWidgetStore.determineWidthAndHeightForOneWidget()
        }
        .animation(
            .bouncy(duration: uiManager.panelState == .open ? 0.3 : 0.1),
            value: uiManager.panelState == .open
        )
    }
}
