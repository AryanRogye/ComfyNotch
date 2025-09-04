import Foundation

public enum MusicProvider: String, Codable, CaseIterable, Identifiable{
    case none
    case apple_music
    case spotify
    
    public var id: String { rawValue }
}

extension MusicProvider {
    var displayName: String {
        switch self {
        case .none : return "None"
        case .spotify : return "Spotify"
        case .apple_music : return "Apple Music"
        }
    }

}
