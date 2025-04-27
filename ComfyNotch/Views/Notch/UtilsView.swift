import SwiftUI

struct UtilsView: View {
    @StateObject var animationState: PanelAnimationState = PanelAnimationState.shared
    var body: some View {
        VStack(spacing: 0) {
            if animationState.isExpanded {
              /// For now just the clipboard
            }
        }
        .background(Color.black)
        .animation(
            .easeInOut(duration: animationState.isExpanded ? 0.3 : 0.1),
            value: animationState.isExpanded
        )
    }
}
