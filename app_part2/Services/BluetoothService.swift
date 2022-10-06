//
//  BluetoothService.swift
//  BleTest WatchKit Extension
//
//  Created by Nikita on 11.11.2021.
//

import Foundation
import CoreBluetooth
import UserNotifications
import RxRelay

typealias BluetoothDeviceInfo = (peripheral: CBPeripheral, rssi: NSNumber)

class BluetoothService: NSObject {
    
    // MARK: - vars
    static let shared = BluetoothService()
    
    let peripheralConnectionRelay = BehaviorRelay<CBPeripheral?>(value: nil)
    
    @Published
    private(set) var discoveredItems: [UUID: BluetoothDeviceInfo] = [:]
    
    @Published
    private(set) var devices: [BluetoothDeviceInfo] = []
    
    @Published
    private(set) var lastDiscoveredItem: BluetoothDeviceInfo? = nil
    
    @Published
    private(set) var isScanning: Bool = false
    
    @Published
    private(set) var connectedPeripheral: CBPeripheral? = nil
    
    private(set) var knownDisconnectedPeripheral: CBPeripheral? = nil
    
    private lazy var central: CBCentralManager = {
        CBCentralManager(delegate: self, queue: .global(qos: .background), options: nil)
    }()
    
    // MARK: - methods
    func beginScanning() {
        isScanning = true
        central.scanForPeripherals(
            withServices: [
                Constants.serviceUUID
            ],
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: false
            ]
        )
    }
    
    func endScanning() {
        central.stopScan()
        isScanning = false
        
        let items = discoveredItems.values.sorted {
            $0.rssi.doubleValue > $1.rssi.doubleValue
        }
        
        devices = items
        discoveredItems = [:]
    }
    
    func connect(to peripheral: CBPeripheral) {
        central.connect(peripheral, options: nil)
    }
    
    func cancellConnection(to peripheral: CBPeripheral) {
        central.cancelPeripheralConnection(peripheral)
    }
    
    func flush() {
        discoveredItems = .init()
        lastDiscoveredItem = nil
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothService: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        if state == .poweredOn {
            beginScanning()
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        let deviceInfo = BluetoothDeviceInfo(peripheral, RSSI)
        if (discoveredItems[peripheral.identifier] == nil) {
            discoveredItems[peripheral.identifier] = deviceInfo
            lastDiscoveredItem = deviceInfo
        }
        print("Discover device", peripheral.name ?? "N/A")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        endScanning()
        discoveredItems.removeAll()
        peripheralConnectionRelay.accept(peripheral)
        connectedPeripheral = peripheral
        knownDisconnectedPeripheral = peripheral
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripheral = nil
        peripheralConnectionRelay.accept(nil)
    }
}

// MARK: - Constants
extension BluetoothService {
    struct Constants {
        static let serviceUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
        static let txCaracreristicUUID = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
        static let rxCaracreristicUUID = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    }
}
