import AppKit
import SwiftUI

enum WidgetAlignment {
    case left
    case right
}

protocol SwiftUIWidget {
    var name: String { get }
    var alignment: WidgetAlignment? { get }
    var swiftUIView: AnyView { get }  // Make it a computed property, not optional
}

extension SwiftUIWidget {
    var alignment: WidgetAlignment? { nil }  // Default to nil unless overridden
}

// protocol Widget {
//     var name: String { get }   // Unique name for the widget
//     var alignment: WidgetAlignment? { get } // Optional alignment, defaulting to nil
//     func update()              // Refresh the widget’s content
//     func show()
//     func hide()

//     // New: Optional SwiftUI view representation
//     var swiftUIView: AnyView? { get }
    
//     // Legacy: NSView representation
//     var view: NSView { get }
// }

// extension Widget {
//     // Provide a default implementation for alignment so it's "optional" for conforming types
//     var alignment: WidgetAlignment? { nil }
//     var swiftUIView: AnyView? { nil }  // Default to nil unless overridden

//     func show() {}
//     func hide() {}
// }