import SwiftUI

struct NotchShape: Shape {
    let curveRadius: CGFloat
    let outwardCurveRadius: CGFloat
    
    init(curveRadius: CGFloat = 30, outwardCurveRadius: CGFloat = 20) {
        self.curveRadius = curveRadius
        self.outwardCurveRadius = outwardCurveRadius
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Start from top-left, but inset to allow for outward curve
        let topInset: CGFloat = 40 // This should match extraCurveWidth/2 from UIManager
        
        // Start point (top-left after inset)
        path.move(to: CGPoint(x: topInset, y: 0))
        
        // Top edge to top-right curve start
        path.addLine(to: CGPoint(x: width - topInset, y: 0))
        
        // Top-right outward curve
        path.addQuadCurve(
            to: CGPoint(x: width, y: outwardCurveRadius),
            control: CGPoint(x: width + outwardCurveRadius, y: 0)
        )
        
        // Right edge
        path.addLine(to: CGPoint(x: width, y: height - curveRadius))
        
        // Bottom-right inward curve
        path.addQuadCurve(
            to: CGPoint(x: width - curveRadius, y: height),
            control: CGPoint(x: width, y: height)
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: curveRadius, y: height))
        
        // Bottom-left inward curve
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height - curveRadius),
            control: CGPoint(x: 0, y: height)
        )
        
        // Left edge
        path.addLine(to: CGPoint(x: 0, y: outwardCurveRadius))
        
        // Top-left outward curve
        path.addQuadCurve(
            to: CGPoint(x: topInset, y: 0),
            control: CGPoint(x: -outwardCurveRadius, y: 0)
        )
        
        path.closeSubpath()
        return path
    }
}

struct RoundedCornersShape: Shape {
    var topLeft: CGFloat = 0
    var topRight: CGFloat = 0
    var bottomLeft: CGFloat = 0
    var bottomRight: CGFloat = 0

    var notchWidth: CGFloat = 0
    var notchHeight: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.size.width
        let height = rect.size.height

        let topLeftRadius = min(min(topLeft, height/2), width/2)
        let topRightRadius = min(min(topRight, height/2), width/2)
        let bottomLeftRadius = min(min(bottomLeft, height/2), width/2)
        let bottomRightRadius = min(min(bottomRight, height/2), width/2)

        let topEdgeLeftX = rect.minX + topLeftRadius
        let topEdgeRightX = rect.maxX - topRightRadius
        let midX = (topEdgeLeftX + topEdgeRightX) / 2

        // 1) Start at top-left
        path.move(to: CGPoint(x: topEdgeLeftX, y: rect.minY))

        if notchWidth > 0 && notchHeight > 0 {
            let notchStartX = midX - notchWidth / 2
            let notchEndX = midX + notchWidth / 2

            // Line to notch start
            path.addLine(to: CGPoint(x: notchStartX - notchHeight / 2, y: rect.minY))

            // Curve down into notch
            path.addQuadCurve(
                to: CGPoint(x: notchStartX, y: rect.minY + notchHeight),
                control: CGPoint(x: notchStartX - notchHeight / 2, y: rect.minY + notchHeight / 2)
            )

            // Line across bottom of notch
            path.addLine(to: CGPoint(x: notchEndX, y: rect.minY + notchHeight))

            // Curve up out of notch
            path.addQuadCurve(
                to: CGPoint(x: notchEndX + notchHeight / 2, y: rect.minY),
                control: CGPoint(x: notchEndX + notchHeight / 2, y: rect.minY + notchHeight / 2)
            )

            // Line to top-right corner start
            path.addLine(to: CGPoint(x: topEdgeRightX, y: rect.minY))
        } else {
            // No notch, just line across
            path.addLine(to: CGPoint(x: topEdgeRightX, y: rect.minY))
        }

        // Top-right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - topRightRadius, y: rect.minY + topRightRadius),
            radius: topRightRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // Right side
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRightRadius))

        // Bottom-right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - bottomRightRadius, y: rect.maxY - bottomRightRadius),
            radius: bottomRightRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // Bottom side
        path.addLine(to: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.maxY))

        // Bottom-left corner
        path.addArc(
            center: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.maxY - bottomLeftRadius),
            radius: bottomLeftRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // Left side
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeftRadius))

        // Top-left corner
        path.addArc(
            center: CGPoint(x: rect.minX + topLeftRadius, y: rect.minY + topLeftRadius),
            radius: topLeftRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )

        path.closeSubpath()
        return path
    }
}
