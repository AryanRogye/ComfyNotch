import AppKit
import SwiftUI
import Combine

struct AlbumWidgetView: View, Widget {
    var alignment: WidgetAlignment? = .left
    var name: String = "AlbumWidget"

    @ObservedObject var model: AlbumWidgetModel
    var scrollManager = ScrollHandler.shared

    var body: some View {
        ZStack {
            if !PanelAnimationState.shared.isExpanded {
                panelButton {
                    Image(nsImage: model.image ?? NSImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 22)
                        .cornerRadius(4)
                        .padding(.top, 2)
                        .opacity(model.image != nil ? 1 : 0)
                }
                
                panelButton {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 27, height: 23)
                        Image(systemName: "music.note")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 1)
                    .opacity(model.image == nil ? 1 : 0)
                }
            } else {
                Text("")
            }
        }
        .padding(.trailing, 22)
        .animation(.easeInOut(duration: 0.25), value: model.image != nil)
    }

    private func panelButton<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        Button(action: scrollManager.openFull ) {
            label()
        }
        .buttonStyle(.plain)
    }

    var swiftUIView: AnyView {
        AnyView(self)
    }
}

class AlbumWidgetModel: ObservableObject {
    @Published var image: NSImage?
    private var cancellables = Set<AnyCancellable>()

    init() {
        AudioManager.shared.$currentArtworkImage
            .receive(on: RunLoop.main)
            .sink { [weak self] newImage in
                self?.image = newImage
            }
            .store(in: &cancellables)
    }
}
