//
//  BluetoothManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 4/29/25.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    public static let   shared = BluetoothManager()
    private var         manager: CBCentralManager!
    @Published var      userBluetoothConnections: [CBPeripheral] = []
    @Published var connectionStates: [UUID: Bool] = [:]
    
    private let services: [CBUUID] = [
        CBUUID(string: "180A"), // Device Information
        CBUUID(string: "180D"), // Heart Rate
        CBUUID(string: "1812")  // HID Service
    ]

    private override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    /// This is the Function that is needed by the CBCentralManagerDelegate
    /// it makes sure that the bluetooth is on and then starts scanning for devices
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            debugLog("Bluetooth not available: \(central.state.rawValue)")
            return
        }
        central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    /// When a new Connection is discovered
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        if !userBluetoothConnections.contains(where: { $0.identifier == peripheral.identifier && $0.name == peripheral.name }) {
            peripheral.delegate = self              // 🔑 must set delegate
            userBluetoothConnections.append(peripheral)
            connectionStates[peripheral.identifier] = false
            debugLog("➕ Discovered: \(peripheral.name ?? peripheral.identifier.uuidString)")
        }
    }

    public func start() {
        if manager == nil {
            manager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    // 3) Connect method
    func connect(_ peripheral: CBPeripheral) {
        debugLog("⏳ Attempting to connect to \(peripheral.name ?? peripheral.identifier.uuidString)...")
        
        // Check if peripheral is already connected
        if peripheral.state == .connected {
            debugLog("⚠️ Device is already connected!")
            return
        }
        
        // Make sure the peripheral has a delegate
        peripheral.delegate = self
        
        // Connect with timeout option for better reliability
        manager.connect(peripheral, options: [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true
        ])
    }

    // 4) Disconnect method
    func disconnect(_ peripheral: CBPeripheral) {
        debugLog("⏳ Attempting to disconnect from \(peripheral.name ?? peripheral.identifier.uuidString)...")
        
        // Check if peripheral is already disconnected
        if peripheral.state != .connected {
            debugLog("⚠️ Device is already disconnected!")
            return
        }
        
        // Disconnect
        manager.cancelPeripheralConnection(peripheral)
    }
    
    private func retrieveConnected() {
        guard let manager = manager else { return }
        
        let peripherals = manager.retrieveConnectedPeripherals(withServices: services)
        peripherals.forEach { addPeripheral($0) }
    }
    
    private func startScanning() {
        manager?.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        debugLog("Started scanning for peripherals")
    }
    
    private func addPeripheral(_ peripheral: CBPeripheral) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Use name if available, fallback to UUID
            let name = peripheral.name ?? peripheral.identifier.uuidString

            // Deduplicate by name
            if !self.userBluetoothConnections.contains(where: { $0.name == peripheral.name }) {
                peripheral.delegate = self
                self.userBluetoothConnections.append(peripheral)
                debugLog("➕ Discovered: \(name)")
            }
        }
    }


    public func stopScanning() {
        manager?.stopScan()
    }
}
