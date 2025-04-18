import SwiftUI

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
