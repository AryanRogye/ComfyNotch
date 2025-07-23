//
//  WidgetRegistry.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/26/25.
//


import SwiftUI

enum WidgetType: String , CaseIterable, Hashable {
    case musicPlayer = "MusicPlayerWidget"
    case time = "TimeWidget"
    case notes = "NotesWidget"
    case camera = "CameraWidget"
    case event = "EventWidget"
    
    var shortName: String {
        switch self {
        case .musicPlayer:
            return "Music Widget"
        case .time:
            return "Time Widget"
        case .notes:
            return "Notes Widget"
        case .camera:
            return "Camera Widget"
        case .event:
            return "Event Widget"
        }
    }
    
    var color: Color {
        switch self {
        case .musicPlayer:
            return Color.purple
        case .time:
            return Color.blue
        case .notes:
            return Color.green
        case .camera:
            return Color.yellow
        case .event:
            return Color.red
        }
    }
    
    var image: Image {
        switch self {
        case .musicPlayer:
            return Image(systemName: "music.note.list")
        case .time:
            return Image(systemName: "sunrise.fill")
        case .notes:
            return Image(systemName: "pencil")
        case .camera:
            return Image(systemName: "camera")
        case .event:
            return Image(systemName: "calendar")
        }
    }
}

extension String {
    var widgetType: WidgetType? {
        WidgetType(rawValue: self)
    }
}


class WidgetRegistry {
    static let shared = WidgetRegistry()
    
    private init() {}
    
    
    /// Delaying widget construction until getWidget is actually called.
    /// This avoids early instantiation of complex widgets on launch.
    /// Helpful for resolving crashes from stale or missing UserDefaults.
    /// To test: `defaults delete app.aryanrogye.ComfyNotch`
    lazy var widgetConstructors: [String: () -> Widget] = [
        "MusicPlayerWidget": { MusicPlayerWidget() },
        "TimeWidget": { TimeWidget() },
        "NotesWidget": { NotesWidget() },
        "CameraWidget": { CameraWidget() },
        "EventWidget": { EventWidget() }
    ]
    
    func getWidget(named name: String) -> Widget? {
        return widgetConstructors[name]?()
    }
    
    func getDefaultWidgets() -> [String] {
        return ["MusicPlayerWidget"]
    }
}
