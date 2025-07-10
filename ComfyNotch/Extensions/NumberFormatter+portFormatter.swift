//
//  NumberFormatter+portFormatter.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/8/25.
//

extension NumberFormatter {
    static var portFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimum = 1
        formatter.maximum = 65535
        formatter.allowsFloats = false
        formatter.numberStyle = .none
        return formatter
    }
}
