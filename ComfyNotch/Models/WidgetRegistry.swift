//
//  WidgetRegistry.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/26/25.
//

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
        "AIChatWidget": { AIChatWidget() },
        "EventWidget": { EventWidget() }
    ]
    
    func getWidget(named name: String) -> Widget? {
        return widgetConstructors[name]?()
    }
    
    func getDefaultWidgets() -> [String] {
        return ["MusicPlayerWidget"]
    }
}
