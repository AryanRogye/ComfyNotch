//
//  Data+init.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/29/25.
//

extension Data {
    init?(hexEncoded string: String) {
        let len = string.count / 2
        var data = Data(capacity: len)
        var index = string.startIndex
        for _ in 0..<len {
            let next = string.index(index, offsetBy: 2)
            guard next <= string.endIndex,
                  let b = UInt8(string[index..<next], radix: 16) else { return nil }
            data.append(b)
            index = next
        }
        self = data
    }
}
