import AppKit
import SwiftUI
import Combine

struct AlbumWidgetView: View, Widget {
    var alignment: WidgetAlignment? = .left
    var name: String = "AlbumWidget"

    @ObservedObject var model: AlbumWidgetModel
    var scrollManager = ScrollHandler.shared
    var body: some View {
        Group {
            if let nsImage = model.image {
                panelButton {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 22)
                        .cornerRadius(4)
                        .padding(.top, 2)
                }
            } else {
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
                }
            }
        }
        .padding(.leading, 10)
    }

    private func panelButton<Label: View>(@ViewBuilder label: () -> Label) -> some View {
        Button(action: scrollManager.open ) {
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
