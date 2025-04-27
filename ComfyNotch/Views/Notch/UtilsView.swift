import SwiftUI

struct UtilsView: View {
    @StateObject var animationState: PanelAnimationState = .shared
    @StateObject var clipboardManager = ClipboardManager.shared

    var body: some View {
        VStack(spacing: 0) {
            if animationState.isExpanded {
              /// For now just the clipboard
              Utils_ClipboardView(clipboardManager: clipboardManager)
                .padding(.top, 10)
                .padding(.horizontal, 10)
                .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.top)
            }
        }
        .background(Color.black)
        .animation(
            .easeInOut(duration: animationState.isExpanded ? 0.3 : 0.1),
            value: animationState.isExpanded
        )
    }
}


struct Utils_ClipboardView: View {
    @ObservedObject var clipboardManager : ClipboardManager
    var body: some View {
        VStack {
            ForEach(clipboardManager.clipboardHistory, id: \.self) { item in
                Text(item)
                   .foregroundColor(.white)
                   .font(.system(size: 13))
                   .frame(maxWidth:.infinity, alignment:.leading)
                   .padding(.horizontal, 10)
                   .padding(.vertical, 4)
                   .background(Color.black)
            }
        }
    }
}