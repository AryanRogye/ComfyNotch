import AppKit

protocol Widget {
    var view: NSView { get }  // Every widget will have its own view
    var name: String { get }   // Unique name for the widget
    func update()              // Refresh the widget’s content
    func show()
    func hide()
}