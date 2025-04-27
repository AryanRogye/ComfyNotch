import SwiftUI

struct RoundedCornersShape: Shape {
  // your per-corner radii
  var topLeft:     CGFloat = 12
  var topRight:    CGFloat = 12
  var bottomLeft:  CGFloat = 12
  var bottomRight: CGFloat = 12

  // notch (“pill”) size
  var notchWidth:  CGFloat = 60
  var notchHeight: CGFloat = 28

  func path(in rect: CGRect) -> Path {
    var p = Path()

    // clamp radii so they never exceed half the rect
    let tl = min(min(topLeft,    rect.height/2), rect.width/2)
    let tr = min(min(topRight,   rect.height/2), rect.width/2)
    let bl = min(min(bottomLeft, rect.height/2), rect.width/2)
    let br = min(min(bottomRight,rect.height/2), rect.width/2)

    let midX   = rect.midX
    let nW     = notchWidth
    let nH     = notchHeight
    let startN = midX - nW/2
    let endN   = midX + nW/2

    // 1) Start at top-left edge
    p.move(to: CGPoint(x: rect.minX, y: rect.minY))

    // 2) concave quarter-curve into top-left
    p.addQuadCurve(
      to:    CGPoint(x: rect.minX + tl,       y: rect.minY + tl),
      control: CGPoint(x: rect.minX + tl,     y: rect.minY)
    )

    // 3) straight line up to just before notch
    p.addLine(to: CGPoint(x: startN - nH/2, y: rect.minY + tl))

    // 4) carve down into notch
    p.addQuadCurve(
      to:    CGPoint(x: startN,          y: rect.minY + tl + nH),
      control: CGPoint(x: startN - nH/2, y: rect.minY + tl + nH/2)
    )

    // 5) across bottom of notch
    p.addLine(to: CGPoint(x: endN,       y: rect.minY + tl + nH))

    // 6) carve back up out of notch
    p.addQuadCurve(
      to:    CGPoint(x: endN + nH/2,    y: rect.minY + tl),
      control: CGPoint(x: endN + nH/2,   y: rect.minY + tl + nH/2)
    )

    // 7) straight to just before top-right corner start
    p.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY + tl))

    // 8) concave quarter-curve out to top-right
    p.addQuadCurve(
      to:    CGPoint(x: rect.maxX,             y: rect.minY),
      control: CGPoint(x: rect.maxX - tr,      y: rect.minY)
    )

    // 9) right edge down to bottom-right
    p.addLine(to: CGPoint(x: rect.maxX,              y: rect.maxY - br))
    p.addArc(
      center: CGPoint(x: rect.maxX - br,            y: rect.maxY - br),
      radius: br,
      startAngle: .degrees(0),
      endAngle:   .degrees(90),
      clockwise: false
    )

    // 10) bottom edge → bottom-left
    p.addLine(to: CGPoint(x: rect.minX + bl,        y: rect.maxY))
    p.addArc(
      center: CGPoint(x: rect.minX + bl,            y: rect.maxY - bl),
      radius: bl,
      startAngle: .degrees(90),
      endAngle:   .degrees(180),
      clockwise: false
    )

    // 11) left edge back up to just below top-left
    p.addLine(to: CGPoint(x: rect.minX,              y: rect.minY + tl))

    p.closeSubpath()
    return p
  }
}
