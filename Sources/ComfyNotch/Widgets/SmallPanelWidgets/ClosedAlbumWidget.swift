import AppKit
import SwiftUI
import Combine

struct AlbumWidgetView: View, Widget {
    var alignment: WidgetAlignment? = .left
    var name: String = "AlbumWidget"

    @ObservedObject var model: AlbumWidgetModel
    var scrollManager  = ScrollHandler.shared
    var body: some View {
        Group {
            if let nsImage = model.image {
                Button(action: { scrollManager.open() }) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 30, height: 30)
                    Image(systemName: "music.note")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
                .frame(width: 25, height: 25)
            }
        }
        .padding(.leading, 10)
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
