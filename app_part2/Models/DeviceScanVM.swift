//
//  DeviceScanVM.swift
//  app_part2
//
//  Created by Ирина Токарева on 05.12.2021.
//

import Foundation
import UIKit
import Combine
import CoreBluetooth
import RxRelay

protocol DeviceScanVMProtocol {
    var isScanningPublisher: Published<Bool>.Publisher { get }
    var itemsRelay: BehaviorRelay<[DevicesSection]> { get }
    var view: UIViewController? { get set }
    
    func startScanning()
    func stopScanning()
    func didSelectItem(at index: Int)
}

class DeviceScanVM: DeviceScanVMProtocol {

    private struct PeripheralContainer: Hashable {
        let peripheral: CBPeripheral
        let index: Int
        
        func hash(into hasher: inout Hasher) {
            peripheral.identifier.hash(into: &hasher)
        }
    }
    
    // MARK: - vars
    var isScanningPublisher: Published<Bool>.Publisher {
        BluetoothService.shared.$isScanning
    }
    
    weak var view: UIViewController? = nil
    var itemsRelay = BehaviorRelay<[DevicesSection]>(value: [])
    
    @Published
    private var lastInsertedIndexPath: IndexPath?
    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable? = nil
    private var latestDiscoveredPeripherals = [CBPeripheral]()
    
    // MARK: - inititialization
    init() {
        BluetoothService.shared.flush()
        setupBindings()
    }
    
    // MARK: - methods
    func startScanning() {
        timerCancellable?.cancel()
        BluetoothService.shared.beginScanning()
        
        timerCancellable = Timer.TimerPublisher(interval: 4.0, runLoop: .main, mode: .default)
            .autoconnect()
            .map { _ in return }
            .sink(receiveValue: toggleScanning)
    }
    
    func stopScanning() {
        timerCancellable?.cancel()
        BluetoothService.shared.endScanning()
    }
    
    func didSelectItem(at index: Int) {
        stopScanning()
        guard
            let section = itemsRelay.value.first,
            index < section.items.count
        else { return }
        let viewModel = DeviceControlVM(peripheral: section.items[index].peripheral)
        let vc = DeviceControlVC(viewModel: viewModel)
        view?.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func setupBindings() {
        BluetoothService.shared.$devices
            .map { devices -> [CBPeripheral] in
                devices.map { $0.peripheral }
            }
            .sink { [weak self] peripherals in
                self?.checkDifference(newPeripherals: peripherals)
            }
            .store(in: &cancellables)
    }
    
    private func toggleScanning() {
        if BluetoothService.shared.isScanning {
            BluetoothService.shared.endScanning()
        } else {
            BluetoothService.shared.beginScanning()
        }
    }
    
    
    private func checkDifference(newPeripherals: [CBPeripheral]) {
        let devices = newPeripherals.map {
            DeviceCellVM(peripheral: $0)
        }
        let sections = [
            DevicesSection(header: "Устройства", items: devices)
        ]
        DispatchQueue.main.async { [weak self] in
            self?.itemsRelay.accept(sections)
        }
        
    }
}
