import AppKit
import SwiftUI

/**
 * Defines the horizontal alignment options for widgets in the panel.
 * Used primarily in the SmallPanel to organize widgets.
 *     - The SmallPanel is wrapped around the notch so cuz of this we
 *       need to define the alignment of the widgets, this way its constant
 *
 * Cases:
 * - left: Aligns widget to the left side of the panel
 * - right: Aligns widget to the right side of the panel
 */
enum WidgetAlignment {
    case left
    case right
}

/**
 * Widget protocol defines the basic structure for all panel widgets.
 * This protocol ensures all widgets have consistent properties for
 * identification, positioning, and view representation.
 *
 * Required Properties:
 * - name: Unique identifier for the widget
 * - alignment: Optional alignment preference (left/right)
 * - swiftUIView: The widget's visual representation
 */
protocol Widget {
    /// Unique identifier for the widget
    var name: String { get }
    
    /// Optional alignment preference for widget positioning
    var alignment: WidgetAlignment? { get }
    
    /// SwiftUI view representation of the widget
    var swiftUIView: AnyView { get }
}

extension Widget {
    /**
     * Default implementation for widget alignment.
     * Returns nil, allowing the panel manager to determine default positioning.
     */
    var alignment: WidgetAlignment? { nil }
}