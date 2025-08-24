//
//  QRCodeView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/23/25.
//

import SwiftUI

struct QRCodeView: View {
    
    
    @EnvironmentObject var settingsCoordinator: SettingsCoordinator
    @EnvironmentObject var qrCodeManager: QRCodeManager
    
    @Binding var hasStartedQRScanning: Bool
    @Binding var hoverErrorStatus: QRCodeManager.QRCodeManagerError
    @ObservedObject var settings = SettingsModel.shared
    
    var body: some View {
        VStack {
            Button(action: {
                hasStartedQRScanning = false
                qrCodeManager.stop()
            }) {
                Text("Close")
            }
            
            switch hoverErrorStatus {
            case .settingsError:
                /// If the settings are not setup right then we can ask the user
                /// to go to that page
                turnOnLocalHostInSettings
                    .foregroundColor(.red)
            case .noFileDropped:
                Text("No File Dropped")
                    .foregroundColor(.red)
            case .serverStartFailed:
                Text("Server Start Failed")
                    .foregroundColor(.red)
            case .qrGenerationFailed:
                Text("QR Code Generation Failed")
            case .portInUse(let int):
                Text("Port is in use: \(int) Please Open Settings")
                    .foregroundColor(.red)
            case .none:
                VStack {
                    if let image = qrCodeManager.createdQRCodeImage {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .padding(.top, 2)
                    }
                }
            }
        }
    }
    
    
    private var turnOnLocalHostInSettings: some View {
        Button(action: openSettings) {
            Text("Turn On LocalHost QR Code in Settings")
                .foregroundColor(.red)
        }
    }
    
    
    private func openSettings() {
        settingsCoordinator.showSettings()
        settings.selectedTab = .notch
        /// 3 means filetray section
        settings.selectedNotchTab = 3
    }
}
