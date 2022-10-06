//
//  DeviceCellVM.swift
//  app_part2
//
//  Created by Ирина Токарева on 05.12.2021.
//

import Foundation
import Combine
import CoreBluetooth
import RxDataSources

enum DeviceCellState {
    case disconnected
    case connecting
    case connected
}

protocol DeviceCellVMProtocol: IdentifiableType {
    var statePublisher: Published<DeviceCellState>.Publisher { get }
    var state: DeviceCellState { get }
    var deviceName: String { get }
    
    var peripheral: CBPeripheral { get }
}

class DeviceCellVM: DeviceCellVMProtocol, Equatable {
    
    var statePublisher: Published<DeviceCellState>.Publisher {
        $state
    }
    
    var deviceName: String {
        peripheral.name ?? "Unnamed"
    }
    
    var identity: CBPeripheral {
        peripheral
    }
    
    @Published
    var state: DeviceCellState
    
    var peripheral: CBPeripheral
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.state = .disconnected
    }
    
    static func == (lhs: DeviceCellVM, rhs: DeviceCellVM) -> Bool {
        return lhs.peripheral == rhs.peripheral
    }
}
