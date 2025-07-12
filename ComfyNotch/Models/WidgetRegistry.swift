//
//  WidgetRegistry.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/26/25.
//

class WidgetRegistry {
    static let shared = WidgetRegistry()
    
    private init() {}
    
    
    /// delaying construction until the "getWidget" is called
    /// this was causing a crash for lots of users, and I belive this should solve it
    /// the way to test is is to run
    /// `defaults delete app.aryanrogye.ComfyNotch` in the terminal
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
