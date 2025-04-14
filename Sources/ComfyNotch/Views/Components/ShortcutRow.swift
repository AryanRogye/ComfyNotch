import SwiftUI


struct ShortcutRows: View {
    
    @State var hoverModifier : ModifierKey = .command
    @State var settingsModifier : ModifierKey = .option
    
    var body: some View {
        /// For Each Content We Get
        ModifierPickerItem(name: "Hover Hide", selected: $hoverModifier)
        ModifierPickerItem(name: "Open Settings", selected: $settingsModifier)
    }
}
