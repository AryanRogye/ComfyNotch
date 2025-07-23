import SwiftUI
import CoreGraphics
import AppKit

struct ComfyNotchShape: Shape {
    var topRadius: CGFloat
    var bottomRadius: CGFloat
    
    init(
        topRadius: CGFloat = 8,
        bottomRadius: CGFloat = 13
    ) {
        self.topRadius = topRadius
        self.bottomRadius = bottomRadius
    }
    
    var animatableData: CGFloat {
        get { bottomRadius }
        set { bottomRadius = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start at top-left corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // Top-left rounded corner (inward curve)
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topRadius, y: rect.minY + topRadius),
            control: CGPoint(x: rect.minX + topRadius, y: rect.minY)
        )
        
        // Left vertical line down to bottom notch area
        path.addLine(to: CGPoint(x: rect.minX + topRadius, y: rect.maxY - bottomRadius * 1.5))
        
        // Bottom-left notch - more organic curve with wider extension
        // First control point creates the initial outward bulge
        path.addCurve(
            to: CGPoint(x: rect.minX + topRadius + bottomRadius * 2.2, y: rect.maxY),
            control1: CGPoint(x: rect.minX + topRadius, y: rect.maxY - bottomRadius * 0.3),
            control2: CGPoint(x: rect.minX + topRadius + bottomRadius * 0.8, y: rect.maxY)
        )
        
        // Bottom horizontal line (shorter to account for wider curves)
        path.addLine(to: CGPoint(x: rect.maxX - topRadius - bottomRadius * 2.2, y: rect.maxY))
        
        // Bottom-right notch - matching organic curve
        path.addCurve(
            to: CGPoint(x: rect.maxX - topRadius, y: rect.maxY - bottomRadius * 1.5),
            control1: CGPoint(x: rect.maxX - topRadius - bottomRadius * 0.8, y: rect.maxY),
            control2: CGPoint(x: rect.maxX - topRadius, y: rect.maxY - bottomRadius * 0.3)
        )
        
        // Right vertical line up to top corner area
        path.addLine(to: CGPoint(x: rect.maxX - topRadius, y: rect.minY + topRadius))
        
        // Top-right rounded corner (inward curve)
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - topRadius, y: rect.minY)
        )
        
        // Top horizontal line back to start
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        
        return path
    }
}
