//
//  QRCodeManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/8/25.
//

import AppKit
import Foundation
import Network
import CoreImage
import CoreImage.CIFilterBuiltins
import SystemConfiguration

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
                serveFileAt: fileDropped
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
                let name = String(cString: interface.ifa_name)
                let family = interface.ifa_addr.pointee.sa_family
                
                if family == UInt8(AF_INET), name == "en0" {
                    var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostBuffer, socklen_t(hostBuffer.count),
                                nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostBuffer)
                    break
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}

enum LocalFileServerError: Error, LocalizedError {
    case portInUse(Int)
    
    var errorDescription: String? {
        switch self {
        case .portInUse(let port):
            return "Port \(port) is already in use. Please choose a different port in settings."
        }
    }
}

final class LocalFileServer {
    private var listener: NWListener?
    
    private var task: Process?
    
    func start(port: Int, serveFileAt fileURL: URL) async throws {
        if task != nil {
            print("Server already running.")
            return
        }
        
        let process = Process()
        process.currentDirectoryURL = fileURL.deletingLastPathComponent()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-m", "http.server", "\(port)"]
        
        let pipe = Pipe()
        process.standardError = pipe
        
        try process.run()
        self.task = process
        
        // Listen for error output
        let errorData = try await readPipeUntilClose(pipe: pipe)
        
        if let errorString = String(data: errorData, encoding: .utf8),
           errorString.contains("Address already in use") {
            stop()
            throw LocalFileServerError.portInUse(port)
        }
        
        print("✅ Server started at localhost:\(port)")
    }
    
    func readPipeUntilClose(pipe: Pipe) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            let handle = pipe.fileHandleForReading
            handle.readabilityHandler = { handle in
                let data = handle.availableData
                handle.readabilityHandler = nil
                continuation.resume(returning: data)
            }
        }
    }
    
    func stop() {
        task?.terminate()
        task = nil
        print("🛑 Server stopped")
    }
}

enum QRCodeGenerator {
    static func generate(from string: String) -> NSImage? {
        let data = Data(string.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        guard let output = filter.outputImage else { return nil }
        let rep = NSCIImageRep(ciImage: output)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }
}
