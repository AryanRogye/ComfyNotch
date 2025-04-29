//
//  BluetoothManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/29/25.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    public static let   shared = BluetoothManager()
    private var         manager: CBCentralManager?
    @Published var      userBluetoothConnections: [CBPeripheral] = []
    
    private let services: [CBUUID] = [
        CBUUID(string: "180A"), // Device Information
        CBUUID(string: "180D"), // Heart Rate
        CBUUID(string: "1812")  // HID Service
    ]

    private override init() {
        /// We can poll for connections later but for now we can do it here
        super.init()
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            print("Bluetooth not available: \(central.state.rawValue)")
            return
        }
        retrieveConnected()
        startScanning()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any], rssi RSSI: NSNumber) {
        addPeripheral(peripheral)
    }

    public func start() {
        if manager == nil {
            manager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    private func retrieveConnected() {
        guard let manager = manager else { return }
        
        let peripherals = manager.retrieveConnectedPeripherals(withServices: services)
        peripherals.forEach { addPeripheral($0) }
    }
    
    private func startScanning() {
        manager?.scanForPeripherals(withServices: nil, options: nil)
        print("Started scanning for peripherals")
    }
    
    private func addPeripheral(_ peripheral: CBPeripheral) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if !self.userBluetoothConnections.contains(where: { $0.identifier == peripheral.identifier }) {
                self.userBluetoothConnections.append(peripheral)
            }
        }
    }

    public func stopScanning() {
        manager?.stopScan()
    }
}
