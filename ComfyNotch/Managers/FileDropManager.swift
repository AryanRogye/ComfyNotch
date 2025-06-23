//
//  FileDropManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 6/22/25.
//

import Cocoa
import UniformTypeIdentifiers

final class FileDropManager: ObservableObject {
    
    @Published var droppedFiles: [URL] = []
    @Published var droppedFileInfo: FileInfo?
    @Published var droppedFile: URL?
    
    private var settings: SettingsModel = .shared
    
    init() {
        self.getFilesFromStoredDirectory()
    }
    
    func handleDrop(providers: [NSItemProvider]) -> Bool {
        
        let fm = FileManager.default
        let sessionDir = fm.temporaryDirectory.appendingPathComponent("FileDropperSession-\(UUID().uuidString)", isDirectory: true)
        try? fm.createDirectory(at: sessionDir, withIntermediateDirectories: true)
        
        for provider in providers {
            
            /// ---------- Finder files ----------
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                
                provider.loadInPlaceFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) {
                    url, inPlace, _ in
                    guard let srcURL = url else { return }
                    
                    self.processFile(at: srcURL,
                                     copyIfNeeded: !inPlace,
                                     sessionDir: sessionDir)
                    
                }
                
                // ---------- Images / screenshots ----------
            } else if provider.canLoadObject(ofClass: NSImage.self) {
                _ = provider.loadObject(ofClass: NSImage.self) { object, _ in
                    guard let img = object as? NSImage,
                          let tiff = img.tiffRepresentation,
                          let rep  = NSBitmapImageRep(data: tiff),
                          let png  = rep.representation(using: .png, properties: [:])
                    else { return }
                    
                    let tmpURL = sessionDir.appendingPathComponent(
                        "DroppedImage-\(UUID()).png")
                    
                    Task.detached(priority: .utility) {
                        try? png.write(to: tmpURL)   // fast, one write
                        await self.processFile(at: tmpURL,
                                               copyIfNeeded: false,
                                               sessionDir: sessionDir)
                    }
                }
            }
            
            // ---------- Promised files ----------
            else if provider.registeredTypeIdentifiers.contains("com.apple.filepromise") {
                provider.loadDataRepresentation(forTypeIdentifier: "com.apple.filepromise") { _, error in
                    if let error = error {
                        debugLog("❌ Failed to receive file promise: \(error)")
                        return
                    }
                    debugLog("ℹ️ File promise received — but not handled in this version")
                }
            }
        }
        
        return true
    }
    
    private func processFile(at url: URL,
                             copyIfNeeded: Bool,
                             sessionDir: URL) {
        Task.detached(priority: .utility) {
            //            guard let (size, hash) = DroppedFileTracker.shared.quickHash(url: url),
            //                  DroppedFileTracker.shared.isNewFile(size: size, hash: hash) else {
            //                debugLog("Duplicate File Detected: \(url)")
            //                return
            //            }
            
            let settings = SettingsModel.shared
            let saveFolder = settings.fileTrayDefaultFolder
            
            try? FileManager.default.createDirectory(at: saveFolder, withIntermediateDirectories: true)
            let destURL = saveFolder.appendingPathComponent(url.lastPathComponent)
            let sourceURL = copyIfNeeded ? url : url // ← future-proof
            try? FileManager.default.copyItem(at: sourceURL, to: destURL)
            
            //            DroppedFileTracker.shared.registerFile(size: size,
            //                                                   hash: hash,
            //                                                   url: destURL)
            
            // 3. Tell SwiftUI
            await MainActor.run {
                self.droppedFile = destURL
                if let info = DroppedFileTracker.shared.extractFileInfo(from: destURL) {
                    self.droppedFileInfo = info
                }
                self.droppedFiles.insert(destURL, at: 0)
            }
        }
    }
    
    private func getFilesFromStoredDirectory() {
        let fileManager = FileManager.default
        let folderURL = settings.fileTrayDefaultFolder
        var matchedFiles: [URL] = []
        /// we wanna return the ones that start with a "DroppedImage" name
        /// This is the one that we added to that selected "Directory", if the user wants to remove
        /// or change the name then it wont show anymore and thats ok, thats up
        /// to them
        if !fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
                debugLog("✅ Created missing folder at: \(folderURL.path)")
            } catch {
                debugLog("❌ Failed to create folder: \(error.localizedDescription)")
                return
            }
        }
        
        /// settings.fileTrayDefaultFolder is the folder to watch for
        do {
            let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil)
            for url in contents {
                if url.lastPathComponent.hasPrefix("Dropped") {
                    matchedFiles.append(url)
                }
            }
        } catch {
            debugLog("There Was A Error Getting Paths \(error.localizedDescription)")
        }
        self.droppedFiles = matchedFiles
    }
    
    public func getFormattedName(for fileURL: URL) -> String {
        let fileName = fileURL.lastPathComponent
        
        // Check if the filename contains "DroppedImage"
        guard let range = fileName.range(of: "DroppedImage") else {
            return fileName  // fallback: return original name if not found
        }
        
        // Cut everything after "DroppedImage"
        let afterPrefix = fileName[range.upperBound...]
        
        // Drop the extension
        return afterPrefix.split(separator: ".").first.map(String.init) ?? String(afterPrefix)
    }
    
    public func getFormattedTimestamp(for fileURL: URL) -> String {
        let createdAt = self.getTimestamp(fileURL: fileURL)
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    private func getTimestamp(fileURL: URL) -> Date {
        do {
            let resourceVlaues =  try fileURL.resourceValues(forKeys: [.creationDateKey])
            return resourceVlaues.creationDate ?? Date()
        } catch {
            debugLog("Error Getting Timestamp \(error.localizedDescription)")
        }
        return Date()
    }
}
