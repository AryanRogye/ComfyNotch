import AppKit
import SwiftUI
import Combine

enum MusicPlayerWidgetStyle: String {
    case native = "Native"
    case comfy = "Comfy"
}

struct MusicPlayerWidget: View, Widget {
    var name: String = "MusicPlayerWidget"
    var swiftUIView: AnyView {
        AnyView(self)
    }
    
    @ObservedObject private var settings = SettingsModel.shared
    
    var body: some View {
        if settings.musicPlayerStyle == .native {
            NativeStyleMusicWidget()
        } else {
            ComfyNotchStyleMusicWidget()
        }
    }
}

class MusicPlayerWidgetModel: ObservableObject {
    static let shared = MusicPlayerWidgetModel()
    
    @Published var isDragging: Bool = false
    @Published var manualDragPosition: Double = 0
    @Published var nowPlayingInfo: NowPlayingInfo = AudioManager.shared.nowPlayingInfo
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        nowPlayingInfo.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}
