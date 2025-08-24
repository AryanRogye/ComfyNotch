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
        
        // MARK: - Top Left Corner
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        
        // Top-left rounded corner (inward curve)
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topRadius, y: rect.minY + topRadius),
            control: CGPoint(x: rect.minX + topRadius, y: rect.minY)
        )
        
        // Left vertical line down to bottom notch area
        path.addLine(to: CGPoint(x: rect.minX + topRadius, y: rect.maxY - bottomRadius * 1.5))
        
        // MARK: - Bottom Left Notch
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + topRadius + bottomRadius * 2.2, y: rect.maxY),
            control: CGPoint(x: rect.minX + topRadius, y: rect.maxY)
        )
        // Bottom horizontal line (shorter to account for wider curves)
        path.addLine(to: CGPoint(x: rect.maxX - topRadius - bottomRadius * 2.2, y: rect.maxY))
        
        // Bottom-right notch - matching organic curve
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - topRadius, y: rect.maxY - bottomRadius * 1.5),
            control: CGPoint(x: rect.maxX - topRadius, y: rect.maxY)
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
