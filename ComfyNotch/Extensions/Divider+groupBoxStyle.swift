//
//  Divider+groupBoxStyle.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/26/25.
//

import SwiftUI

extension Divider {
    /// just enough to look nice inside the GroupBox
    func groupBoxStyle() -> some View {
        self.padding(.horizontal, -6)
    }
}
