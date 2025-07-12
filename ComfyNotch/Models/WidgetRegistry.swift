//
//  WidgetRegistry.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/26/25.
//

class WidgetRegistry {
    static let shared = WidgetRegistry()
    
    private init() {}
    
    var widgetConstructors: [String: () -> Widget] = [
        "MusicPlayerWidget": { MusicPlayerWidget() },
        "TimeWidget": { TimeWidget() },
        "NotesWidget": { NotesWidget() },
        "CameraWidget": { CameraWidget() },
        "AIChatWidget": { AIChatWidget() },
        "EventWidget": { EventWidget() }
    ]
    
    func getWidget(named name: String) -> Widget? {
        return widgetConstructors[name]?()
    }
    
    func getDefaultWidgets() -> [String] {
        return ["MusicPlayerWidget", "TimeWidget"]
    }
}
