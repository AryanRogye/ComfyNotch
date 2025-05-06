//
//  Utils_BluetoothView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/5/25.
//

import SwiftUI
import CoreBluetooth

struct Utils_BluetoothView: View {
    @ObservedObject private var bluetoothManager: BluetoothManager = .shared
    var devicesWithUniqueNames: [CBPeripheral] {
        var uniqueNames = Set<String>()
        var result: [CBPeripheral] = []
        
        for device in bluetoothManager.userBluetoothConnections {
            guard let name = device.name else { continue } // Skip unnamed devices
            
            // If we haven't seen this name before, add it to our results
            if !uniqueNames.contains(name) {
                uniqueNames.insert(name)
                result.append(device)
            }
        }
        
        return result
    }
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(devicesWithUniqueNames, id: \.self) { device in
                        HStack {
                            Text(device.name ?? "Unknown Device")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                            Spacer()
                            Button(action: { bluetoothManager.disconnect(device) }) {
                                Image(systemName: "bolt.slash.circle.fill")
                                    .resizable()
                                    .frame(width: 20, height: 24)
                            }
                            .buttonStyle(.plain)
                            Button(action: { bluetoothManager.connect(device) }) {
                                Image(systemName: "bolt.horizontal.circle.fill")
                                    .resizable()
                                    .frame(width: 20, height: 24)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 2)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.trailing, 8)
                }
                
            }
        }
        .onAppear {
            bluetoothManager.start()
        }
        .onDisappear {
            bluetoothManager.stopScanning()
        }
        .padding(.top, 2)
        .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.top)
    }
}
