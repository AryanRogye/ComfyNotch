//
//  QRCodeManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/8/25.
//

import AppKit
import Foundation
import Network

/// Function is used to start a localhost server with the image then having a
@MainActor
final class QRCodeManager: ObservableObject {
    
    @Published var createdQRCodeText: String? = nil
    @Published var createdQRCodeImage: NSImage? = nil
    
    let settings = SettingsModel.shared
    var fileDropManager : FileDropManager? = nil
    let localFileServer = LocalFileServer()
    
    init() {
    }
    
    enum QRCodeManagerError: Error {
        case settingsError
        case noFileDropped
        case serverStartFailed
        case qrGenerationFailed
        case portInUse(Int)
        case none
    }
    
    public func assignFileDropManager(_ fileDropManager: FileDropManager) {
        self.fileDropManager = fileDropManager
    }
    
    // MARK: - Start
    public func start() async -> QRCodeManagerError {
        defer { if createdQRCodeImage == nil { localFileServer.stop() } }
        /// Make sure we have a qr code image
        guard let fileDropManager = fileDropManager else { return .noFileDropped }
        guard settings.fileTrayAllowOpenOnLocalhost else { return .settingsError }
        guard let fileDropped = fileDropManager.droppedFile else {
            print("No file dropped to serve.")
            return .noFileDropped
        }
        
        let port = settings.fileTrayPort
        let fileName = fileDropped.lastPathComponent
        let ip = getLocalIPAddress() ?? "localhost"
        let localURL = URL(string: "http://\(ip):\(port)/\(fileName)")!
        
        do {
            try await localFileServer.start(
                port: port,
                serveFileAt: fileDropped,
                with: settings.localHostPin
            )
        } catch LocalFileServerError.portInUse(let port) {
            return .portInUse(port)
        } catch {
            print("❌ Failed to start server: \(error)")
            return .serverStartFailed
        }
        
        if let image = QRCodeGenerator.generate(from: localURL.absoluteString) {
            self.createdQRCodeImage = image
            self.createdQRCodeText = localURL.absoluteString
            print("✅ QR code ready: \(localURL.absoluteString)")
        } else {
            print("❌ Failed to generate QR image.")
            return .qrGenerationFailed
        }
        
        return .none
    }
    
    // MARK: - Stop
    public func stop() {
        clear()
        localFileServer.stop()
    }
    
    // MARK: - QR Assignments
    public func clear() {
        createdQRCodeText = nil
        createdQRCodeImage = nil
    }
    
    func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                let interface = ptr!.pointee
                let family = interface.ifa_addr.pointee.sa_family
                
                if family == UInt8(AF_INET) {
                    let name = String(cString: interface.ifa_name)
                    guard name != "lo0" else { continue }

                    var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostBuffer, socklen_t(hostBuffer.count),
                        nil, 0, NI_NUMERICHOST)

                    let potentialAddress = String(cString: hostBuffer)

                    if potentialAddress.hasPrefix("192.") || potentialAddress.hasPrefix("10.") || potentialAddress.hasPrefix("172.") {
                        address = potentialAddress
                        break
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}
