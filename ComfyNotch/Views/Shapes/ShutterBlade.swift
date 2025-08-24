//
//  ShutterBlade.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/22/25.
//

import Foundation
import SwiftUI

struct ShutterBlade: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        let startAngle = Angle.degrees(-10)
        let endAngle = Angle.degrees(10)
        
        var path = Path()
        
        // 1. Start at center
        path.move(to: center)
        
        // 2. Line to outer edge (at startAngle)
        path.addLine(to: CGPoint(
            x: center.x + radius * cos(CGFloat(startAngle.radians)),
            y: center.y + radius * sin(CGFloat(startAngle.radians))
        ))
        
        // 3. Arc along outer circle
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        
        // 4. Line back to center
        path.addLine(to: center)
        
        return path
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ShutterBlade()
            .fill(Color.white)
            .frame(width: 200, height: 200)
    }
}
