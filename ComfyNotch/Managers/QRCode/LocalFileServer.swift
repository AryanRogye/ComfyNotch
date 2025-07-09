//
//  LocalFileServer.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/8/25.
//

import Network
import AppKit

// MARK: - LocalFileServer
final class LocalFileServer {
    
    private var listener: NWListener?
    private var connections: [ObjectIdentifier : NWConnection] = [:]
    private var fileURL: URL?
    
    // ──────────────────────────────────────────────────────────────────────────────
    //  Start
    // ──────────────────────────────────────────────────────────────────────────────
    func start(port: Int, serveFileAt fileURL: URL) async throws {
        guard listener == nil else {
            print("Server already running.")
            return
        }
        
        self.fileURL = fileURL
        
        // Listener
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            throw LocalFileServerError.invalidPort(port)
        }
        
        let listener = try NWListener(using: params, on: nwPort)
        self.listener = listener
        
        listener.newConnectionHandler = { [weak self] conn in
            self?.handleConnection(conn)
        }
        
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("✅ Server ready on port \(port)")
            case .failed(let err):
                print("❌ Listener failed: \(err)")
            case .cancelled:
                print("🛑 Listener cancelled")
            default: break
            }
        }
        
        listener.start(queue: .main)
        
        // Wait a tick so the state becomes .ready / .failed
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let state = listener.state
        if case let .failed(error) = state {
            if (error as? POSIXError)?.code == .EADDRINUSE {
                throw LocalFileServerError.portInUse(port)
            }
            throw error
        }
    }
    
    // ──────────────────────────────────────────────────────────────────────────────
    //  Connection lifecycle
    // ──────────────────────────────────────────────────────────────────────────────
    private func handleConnection(_ connection: NWConnection) {
        // add
        connections[ObjectIdentifier(connection)] = connection
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                self?.receiveRequest(on: connection)
            case .cancelled, .failed:
                self?.connections.removeValue(forKey: ObjectIdentifier(connection))
            default: break
            }
        }
        
        connection.start(queue: .main)
    }
    
    private func receiveRequest(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1,
                           maximumLength: 8_192) { [weak self] data, _, _, error in
            if let error = error {
                print("❌ Receive error: \(error)")
                connection.cancel()
                return
            }
            guard let data = data, !data.isEmpty else {
                connection.cancel()
                return
            }
            self?.processHTTPRequest(data: data, connection: connection)
        }
    }
    
    // ──────────────────────────────────────────────────────────────────────────────
    //  Simple one-file HTTP handler
    // ──────────────────────────────────────────────────────────────────────────────
    private func processHTTPRequest(data: Data, connection: NWConnection) {
        guard
            let request = String(data: data, encoding: .utf8),
            let requestLine = request.components(separatedBy: "\r\n").first,
            requestLine.hasPrefix("GET ")
        else {
            sendError("400 Bad Request", to: connection); return
        }
        serveFile(to: connection)          // ignore path – always serve dropped file
    }
    
    private func serveFile(to connection: NWConnection) {
        guard let url = fileURL else {
            sendError("404 Not Found", to: connection); return
        }
        do {
            let bytes = try Data(contentsOf: url)
            let mime  = mimeType(for: url)
            let head =
"""
HTTP/1.1 200 OK\r\n\
Content-Type: \(mime)\r\n\
Content-Length: \(bytes.count)\r\n\
Content-Disposition: inline; filename="\(url.lastPathComponent)"\r\n\
Connection: close\r\n\
\r\n
"""
            var response = Data(head.utf8)
            response.append(bytes)
            connection.send(content: response, completion: .contentProcessed { _ in
                connection.cancel()
            })
        } catch {
            print("❌ File read error: \(error)")
            sendError("500 Internal Server Error", to: connection)
        }
    }
    
    private func sendError(_ status: String, to connection: NWConnection) {
        let body = "\(status)\n"
        let data =
"""
HTTP/1.1 \(status)\r\n\
Content-Type: text/plain\r\n\
Content-Length: \(body.count)\r\n\
Connection: close\r\n\
\r\n\
\(body)
""".data(using: .utf8)!
        connection.send(content: data, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    // ──────────────────────────────────────────────────────────────────────────────
    //  Helpers
    // ──────────────────────────────────────────────────────────────────────────────
    private func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "jpg","jpeg": return "image/jpeg"
        case "png":        return "image/png"
        case "gif":        return "image/gif"
        case "pdf":        return "application/pdf"
        case "txt":        return "text/plain"
        case "html","htm": return "text/html"
        case "json":       return "application/json"
        case "zip":        return "application/zip"
        case "mp4":        return "video/mp4"
        case "mp3":        return "audio/mpeg"
        default:           return "application/octet-stream"
        }
    }
    
    // ──────────────────────────────────────────────────────────────────────────────
    //  Stop
    // ──────────────────────────────────────────────────────────────────────────────
    func stop() {
        listener?.cancel()
        listener = nil
        connections.values.forEach { $0.cancel() }
        connections.removeAll()
        print("🛑 Server stopped")
    }
}

// MARK: - Errors
enum LocalFileServerError: Error, LocalizedError {
    case portInUse(Int)
    case invalidPort(Int)
    
    var errorDescription: String? {
        switch self {
        case .portInUse(let p):   "Port \(p) is already in use."
        case .invalidPort(let p): "Invalid port \(p)."
        }
    }
}

// MARK: - QR Code Helper
enum QRCodeGenerator {
    static func generate(from string: String) -> NSImage? {
        guard
            let filter = CIFilter(name: "CIQRCodeGenerator"),
            let data   = string.data(using: .utf8)
        else { return nil }
        
        filter.setValue(data, forKey: "inputMessage")
        
        guard
            let rawImg = filter.outputImage?
                .transformed(by: .init(scaleX: 10, y: 10))      // crisp scaling
        else { return nil }
        
        let rep   = NSCIImageRep(ciImage: rawImg)
        let image = NSImage(size: rep.size)
        image.addRepresentation(rep)
        return image
    }
}
