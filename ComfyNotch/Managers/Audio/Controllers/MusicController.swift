//
//  MusicController.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/21/25.
//

enum MusicController: String, Codable, CaseIterable, Identifiable{
    case mediaRemote
    case spotify_music
    
    var id: String { rawValue }
}

extension MusicController {
    var displayName: String {
        switch self {
        case .mediaRemote : return "Media Remote"
        case .spotify_music : return "Spotify/Apple Music"
        }
    }
}
