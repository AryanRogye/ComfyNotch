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
    
    private var accessPIN: String? = nil
    private var hasServed: Bool = false
    
    private var timeoutWorkItem: DispatchWorkItem?
    
    // ──────────────────────────────────────────────────────────────────────────────
    //  Start
    // ──────────────────────────────────────────────────────────────────────────────
    func start(port: Int, serveFileAt fileURL: URL, with accessPIN: String) async throws {
        guard listener == nil else {
            print("Server already running.")
            return
        }
        
        hasServed = false
        self.accessPIN = accessPIN

        self.fileURL = fileURL

        // Listener
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        
        /// Checking for a valid port number
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            throw LocalFileServerError.invalidPort(port)
        }
        
        let listener = try NWListener(using: params, on: nwPort)
        self.listener = listener
        
        listener.newConnectionHandler = { [weak self] conn in
            self?.handleConnection(conn)
        }
        
        /// Handling the state of the listener
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
        /// We handle the case of if the listener failed
        if case let .failed(error) = state {
            if case let .posix(code) = error, code == .EADDRINUSE {
                throw LocalFileServerError.portInUse(port)
            }
            throw error
        }
        
        scheduleTimeout()
    }
    
    @preconcurrency
    private func scheduleTimeout() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = DispatchWorkItem { [unowned self] in
            if !self.hasServed {
                print("⌛️ Timeout – shutting down")
                self.stop()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 60, execute: timeoutWorkItem!)
    }
    
    
    private func processHTTPRequest(data: Data, connection: NWConnection) {
        guard
            let request = String(data: data, encoding: .utf8),
            let requestLine = request.components(separatedBy: "\r\n").first,
            requestLine.hasPrefix("GET ")
        else {
            sendError("400 Bad Request", to: connection)
            return
        }
        
        let path = requestLine.components(separatedBy: " ")[1]
        
        // Debug logging
        print("Received request: \(requestLine)")
        print("Path: \(path)")
        
        if path.contains("?pin=") {
            handlePINSubmission(path: path, connection: connection)
        } else {
            servePINEntryPage(to: connection)
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
Content-Disposition: attachment; filename="\(url.lastPathComponent)"\r\n\
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
    
    private func servePINEntryPage(to connection: NWConnection) {
        let html = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>PIN Entry</title>
</head>
<body style="font-family: sans-serif; text-align: center; padding-top: 40px;">
    <h2>🔐 Enter PIN to Download</h2>
    <form method="GET" action="/">
        <input type="text" name="pin" placeholder="Enter PIN" required 
               style="font-size: 18px; padding: 8px; margin-right: 10px;" 
               autocomplete="off" />
        <button type="submit" style="font-size: 18px; padding: 8px 16px;">Submit</button>
    </form>
    <script>
        // Auto-focus the input field
        document.querySelector('input[name="pin"]').focus();
        
        // Add form submission logging
        document.querySelector('form').addEventListener('submit', function(e) {
            console.log('Form submitting with PIN:', document.querySelector('input[name="pin"]').value);
        });
    </script>
</body>
</html>
"""
        
        let data = html.data(using: .utf8)!
        let response = """
HTTP/1.1 200 OK\r\n\
Content-Type: text/html; charset=UTF-8\r\n\
Content-Length: \(data.count)\r\n\
Connection: close\r\n\
\r\n
""".data(using: .utf8)! + data
        
        connection.send(content: response, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
    
    private func handlePINSubmission(path: String, connection: NWConnection) {
        guard let expectedPIN = accessPIN else {
            print("❌ No PIN configured")
            sendError("500 Server Error", to: connection)
            return
        }
        
        // Better PIN extraction
        let components = path.components(separatedBy: "=")
        guard components.count >= 2 else {
            print("❌ Invalid PIN format in path: \(path)")
            sendError("400 Bad Request", to: connection)
            return
        }
        
        // Get everything after the first "=" and URL decode it
        let submittedPIN = components.dropFirst().joined(separator: "=")
            .removingPercentEncoding ?? ""
        
        print("🔐 PIN comparison:")
        print("   Expected: '\(expectedPIN)'")
        print("   Submitted: '\(submittedPIN)'")
        print("   Match: \(submittedPIN == expectedPIN)")
        
        if submittedPIN == expectedPIN {
            guard !hasServed else {
                print("⚠️ File already served")
                sendError("410 Gone - Already Served", to: connection)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.stop()
                }
                return
            }
            
            print("✅ PIN correct, serving file")
            timeoutWorkItem?.cancel()
            timeoutWorkItem = nil
            hasServed = true
            serveFile(to: connection)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.stop()
            }
        } else {
            print("❌ PIN incorrect")
            sendError("403 Forbidden - Wrong PIN", to: connection)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.stop()
            }
        }
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
        guard listener != nil else { return }
        listener?.cancel()
        listener = nil
        
        connections.values.forEach { $0.cancel() }
        connections.removeAll()
        
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
        
        fileURL   = nil
        accessPIN = nil
        hasServed = false
        
        print("🛑 Server stopped")
    }
}

// MARK: - Errors
enum LocalFileServerError: Error, LocalizedError {
    case portInUse(Int)
    case invalidPort(Int)
    case serverStartFailed
    
    var errorDescription: String? {
        switch self {
        case .portInUse(let p):   "Port \(p) is already in use."
        case .invalidPort(let p): "Invalid port \(p)."
        case .serverStartFailed: "Failed to start the server."
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
