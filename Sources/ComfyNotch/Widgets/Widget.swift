import AppKit

enum WidgetAlignment {
    case left
    case right
}

protocol Widget {
    var view: NSView { get }  // Every widget will have its own view
    var name: String { get }   // Unique name for the widget
    var alignment: WidgetAlignment? { get } // Optional alignment, defaulting to nil
    func update()              // Refresh the widget’s content
    func show()
    func hide()
}

extension Widget {
    // Provide a default implementation for alignment so it's "optional" for conforming types
    var alignment: WidgetAlignment? { nil }
}