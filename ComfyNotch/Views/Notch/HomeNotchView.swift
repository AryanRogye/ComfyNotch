import SwiftUI

struct HomeNotchView: View {
    
    @EnvironmentObject var bigWidgetStore: ExpandedWidgetsStore
    @ObservedObject var notchStateManager = NotchStateManager.shared
    @ObservedObject var settingsModel = SettingsModel.shared

    var body: some View {
        VStack {
            if notchStateManager.isExpanded {
                /// Big Panel Widgets
                ZStack {
                    HStack(spacing: 2) {
                        let lastVisibleIndex = bigWidgetStore.widgets.lastIndex(where: { $0.isVisible })

                        ForEach(bigWidgetStore.widgets.indices, id: \.self) { index in
                            let widgetEntry = bigWidgetStore.widgets[index]
                            if widgetEntry.isVisible {
                                HStack(spacing: 0) {
                                    widgetEntry.widget.swiftUIView
                                        .frame(maxWidth: .infinity)

                                    if settingsModel.showDividerBetweenWidgets,
                                       let lastVisibleIndex,
                                       index < lastVisibleIndex {
                                        Divider()
                                            .background(.ultraThinMaterial)
                                            .frame(width: 1)
                                            .padding(.vertical, 12)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .animation(
            .easeInOut(duration: notchStateManager.isExpanded ? 0.3 : 0.1),
            value: notchStateManager.isExpanded
        )
    }
}
