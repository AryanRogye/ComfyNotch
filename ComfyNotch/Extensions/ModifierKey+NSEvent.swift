import SwiftUI

extension ModifierKey {
    var eventFlag: NSEvent.ModifierFlags {
        switch self {
        case .command: return .command
        case .control: return .control
        case .option: return .option
        case .shift: return .shift
        }
    }
}
