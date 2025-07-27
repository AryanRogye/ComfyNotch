//
//  ConnectivityManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/23/25.
//

import SwiftUI
import CoreAudio

struct AudioDevice {
    let id: AudioDeviceID
    let name: String
}

final class ConnectivityManager: ObservableObject {
    
    @Published var audioDevices: [AudioDevice] = []
    
    init() {
        getOutputAudioDevices()
        
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject),
                                            &address,
                                            DispatchQueue.main) { [weak self] (_, _) in
            self?.getOutputAudioDevices()
        }
    }
    
    func getOutputAudioDevices() {
        var deviceCount: UInt32 = 0
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        // Get the number of devices
        let status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize
        )
        
        guard status == noErr else {
            print("Error getting audio device count: \(status)")
            return
        }
        
        deviceCount = propertySize / UInt32(MemoryLayout<AudioDeviceID>.size)
        
        var deviceIDs = [AudioDeviceID](repeating: 0, count: Int(deviceCount))
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &deviceIDs
        )
        
        var audioDevices: [AudioDevice] = []
        
        for deviceID in deviceIDs {
            // Check if device has output streams
            var streamsPropertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            var streamsSize: UInt32 = 0
            AudioObjectGetPropertyDataSize(deviceID, &streamsPropertyAddress, 0, nil, &streamsSize)
            let streamCount = streamsSize / UInt32(MemoryLayout<AudioStreamID>.size)
            if streamCount == 0 { continue }
            
            // Get device name
            var nameBuffer = [UInt8](repeating: 0, count: 256)
            var nameSize = UInt32(nameBuffer.count)
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioObjectPropertyName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            let status = nameBuffer.withUnsafeMutableBytes { ptr in
                AudioObjectGetPropertyData(deviceID, &nameAddress, 0, nil, &nameSize, ptr.baseAddress!)
            }
            if status == noErr {
                let name = String(bytes: nameBuffer.prefix(Int(nameSize)), encoding: .utf8) ?? "Unknown"
                audioDevices.append(AudioDevice(id: deviceID, name: name))
            }
        }
        
        self.audioDevices = audioDevices
    }
    
}
