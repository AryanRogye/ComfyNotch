//
//  HoverHandler.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/21/25.
//

enum HoverTarget: String, Codable, CaseIterable, Identifiable {
    case album
    case panel
    
    var id: String { rawValue }
}

extension HoverTarget {
    var displayName: String {
        switch self {
        case .album: return "Album Image Only"
        case .panel: return "Whole Panel"
        }
    }
}
