import AppKit

let minimumSupportedVersion = OperatingSystemVersion(majorVersion: 14, minorVersion: 0, patchVersion: 0) // macOS 14 (Sonoma)

if !ProcessInfo.processInfo.isOperatingSystemAtLeast(minimumSupportedVersion) {
    let alert = NSAlert()
    alert.messageText = "Unsupported macOS Version"
    alert.informativeText = "ComfyNotch requires macOS 14 (Sonoma) or higher. Please update your system."
    alert.alertStyle = .critical
    alert.runModal()
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()