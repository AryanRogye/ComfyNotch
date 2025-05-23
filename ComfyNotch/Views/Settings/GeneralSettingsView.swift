import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var settings: SettingsModel
    @Environment(\.colorScheme) var colorScheme

    private let maxWidgetCount = 3  // Limit to 3 widgets

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                cameraSettingsSection
                dividerSettingsSection
                Spacer()
                exitButton
            }
            .padding()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("ComfyNotch Settings")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.top, 12)
    }
    
    
    private var dividerSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Divider Settings")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            Toggle("Enable Divider", isOn: $settings.showDividerBetweenWidgets)
                .onChange(of: settings.showDividerBetweenWidgets) {
                    settings.saveSettings()
                }
                .padding(.vertical, 8)
        }
    }

    private var cameraSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Camera Settings")
                    .font(.headline)
                Spacer()
            }

            Divider()

            Toggle("Flip Camera", isOn: $settings.isCameraFlipped)
                .onChange(of: settings.isCameraFlipped) { settings.saveSettings() }
                .padding(.vertical, 8)
        }
    }

    
    private var exitButton: some View {
        Button(action: closeWindow) {
            Text("Exit ComfyNotch")
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }

    func formatWidgetName(_ name: String) -> String {
        var displayName = name
        if displayName.hasSuffix("Widget") {
            displayName = String(displayName.dropLast(6))
        }
        var formattedName = ""
        for char in displayName {
            if char.isUppercase && !formattedName.isEmpty {
                formattedName += " "
            }
            formattedName += String(char)
        }
        return formattedName
    }

    func getIconName(for widgetName: String) -> String {
        switch widgetName {
        case "MusicPlayerWidget":
            return "music.note"
        case "TimeWidget":
            return "clock"
        case "NotesWidget":
            return "note.text"
        case "CameraWidget":
            return "camera"
        default:
            return "square"
        }
    }
    func closeWindow() {
        NSApp.terminate(nil)
    }
}

#Preview {
    GeneralSettingsView(settings: SettingsModel.shared)
}
