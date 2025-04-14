import SwiftUI

// struct RoundedCornersShape: Shape {
//     var topLeft: CGFloat = 0
//     var topRight: CGFloat = 0
//     var bottomLeft: CGFloat = 0
//     var bottomRight: CGFloat = 0

//     func path(in rect: CGRect) -> Path {
//         var path = Path()

//         let width = rect.size.width
//         let height = rect.size.height

//         let topLeftRadius = min(min(topLeft, height/2), width/2)
//         let topRightRadius = min(min(topRight, height/2), width/2)
//         let bottomLeftRadius = min(min(bottomLeft, height/2), width/2)
//         let bottomRightRadius = min(min(bottomRight, height/2), width/2)

//         path.move(to: CGPoint(x: rect.minX + topLeftRadius, y: rect.minY))
//         path.addLine(to: CGPoint(x: rect.maxX - topRightRadius, y: rect.minY))
//         path.addArc(
//                     center: CGPoint(x: rect.maxX - topRightRadius, y: rect.minY + topRightRadius),
//                     radius: topRightRadius,
//                     startAngle: .degrees(-90),
//                     endAngle: .degrees(0),
//                     clockwise: false
//         )

//         path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRightRadius))
//         path.addArc(
//                     center: CGPoint(x: rect.maxX - bottomRightRadius, y: rect.maxY - bottomRightRadius),
//                     radius: bottomRightRadius,
//                     startAngle: .degrees(0),
//                     endAngle: .degrees(90),
//                     clockwise: false
//         )

//         path.addLine(to: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.maxY))
//         path.addArc(
//                     center: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.maxY - bottomLeftRadius),
//                     radius: bottomLeftRadius,
//                     startAngle: .degrees(90),
//                     endAngle: .degrees(180),
//                     clockwise: false
//         )

//         path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeftRadius))
//         path.addArc(
//                     center: CGPoint(x: rect.minX + topLeftRadius, y: rect.minY + topLeftRadius),
//                     radius: topLeftRadius,
//                     startAngle: .degrees(180),
//                     endAngle: .degrees(270),
//                     clockwise: false
//         )

//         path.closeSubpath()

//         return path
//     }
// }

struct RoundedCornersShape: Shape {
    var topLeft: CGFloat = 0
    var topRight: CGFloat = 0
    var bottomLeft: CGFloat = 0
    var bottomRight: CGFloat = 0

    // Add these two for the notch
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

        // Figure out the horizontal midpoint between the top-left and top-right arcs,
        // so we know where to place the notch cutout.
        let topEdgeLeftX  = rect.minX + topLeftRadius
        let topEdgeRightX = rect.maxX - topRightRadius
        let midX = (topEdgeLeftX + topEdgeRightX) / 2

        // 1) Move to top-left corner
        path.move(to: CGPoint(x: topEdgeLeftX, y: rect.minY))

        // 2) Go right until we reach the start of the notch (if notchWidth > 0)
        //    Otherwise, just go all the way to topEdgeRightX.
        if notchWidth > 0 && notchHeight > 0 {
            path.addLine(to: CGPoint(x: midX - notchWidth/2, y: rect.minY))

            // 3) Draw the notch “down, across, and back up”
            path.addLine(to: CGPoint(x: midX - notchWidth/2, y: rect.minY + notchHeight))
            path.addLine(to: CGPoint(x: midX + notchWidth/2, y: rect.minY + notchHeight))
            path.addLine(to: CGPoint(x: midX + notchWidth/2, y: rect.minY))

            // 4) Continue on to the top-right arc start
            path.addLine(to: CGPoint(x: topEdgeRightX, y: rect.minY))
        } else {
            // No notch, normal top line
            path.addLine(to: CGPoint(x: topEdgeRightX, y: rect.minY))
        }

        // 5) Top-right corner arc
        path.addArc(
            center: CGPoint(x: rect.maxX - topRightRadius, y: rect.minY + topRightRadius),
            radius: topRightRadius,
            startAngle: .degrees(-90),
            endAngle: .degrees(0),
            clockwise: false
        )

        // 6) Right edge -> bottom-right corner arc
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRightRadius))
        path.addArc(
            center: CGPoint(x: rect.maxX - bottomRightRadius, y: rect.maxY - bottomRightRadius),
            radius: bottomRightRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // 7) Bottom edge -> bottom-left corner arc
        path.addLine(to: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.maxY - bottomLeftRadius),
            radius: bottomLeftRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // 8) Left edge -> top-left corner arc
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeftRadius))
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
