import SwiftUI

struct HomeNotchView: View {
    
    @EnvironmentObject var bigWidgetStore: ExpandedWidgetsStore
    @StateObject var animationState = PanelAnimationState.shared
    @StateObject var settingsModel = SettingsModel.shared

    var body: some View {
        VStack {
            if animationState.isExpanded {
                /// Big Panel Widgets
                ZStack {
                    Color.black.opacity(1)
                        .clipShape(RoundedCornersShape(
                            topLeft: 10,
                            topRight: 10,
                            bottomLeft: 10,
                            bottomRight: 10
                        ))
                    HStack(spacing: 2) {
                        ForEach(bigWidgetStore.widgets.indices, id: \.self) { index in
                            let widgetEntry = bigWidgetStore.widgets[index]
                            Group {
                                if widgetEntry.isVisible {
                                    HStack(spacing: 0) {
                                        widgetEntry.widget.swiftUIView
                                            .padding(.horizontal, 2)
                                            .frame(maxWidth: .infinity)
                                            .layoutPriority(1) // make them expand evenly
                                            .padding(.trailing, 2)
                                            .padding(.leading, 4)
                                        
                                        if settingsModel.showDividerBetweenWidgets {
                                            if index < bigWidgetStore.widgets.indices.last(where: { bigWidgetStore.widgets[$0].isVisible })! {
                                                //                                        Rectangle()
                                                //                                            .frame(width: 1)
                                                //                                            .foregroundColor(.white.opacity(0.1))
                                                //                                            .padding(.vertical, 12)
                                                Divider()
                                                    .background(.ultraThinMaterial)
                                                    .frame(width: 1)
                                                    .padding(.vertical, 12)
                                            }
                                        }
                                    }
                                }
                            }
                            .animation(Anim.spring, value: widgetEntry.isVisible ? 1 : 1)
                        }
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
        .animation(
            .easeInOut(duration: animationState.isExpanded ? 0.3 : 0.1),
            value: animationState.isExpanded
        )
    }
}
