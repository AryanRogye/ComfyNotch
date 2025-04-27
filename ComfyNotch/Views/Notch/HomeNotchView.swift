import SwiftUI

struct HomeNotchView: View {
    @EnvironmentObject var bigWidgetStore: ExpandedWidgetsStore
    @ObservedObject var animationState = PanelAnimationState.shared

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
                    HStack(spacing: 0) {
                        ForEach(bigWidgetStore.widgets.indices, id: \.self) { index in
                            let widgetEntry = bigWidgetStore.widgets[index]
                            if widgetEntry.isVisible {
                                widgetEntry.widget.swiftUIView
                                    .padding(.horizontal, 2)
                                    .frame(maxWidth: .infinity)
                                    .layoutPriority(1) // make them expand evenly
                                    .padding(.horizontal, 2)
                            }
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
