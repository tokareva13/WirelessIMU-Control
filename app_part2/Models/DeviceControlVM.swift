//
//  DeviceControlVM.swift
//  app_part2
//
//  Created by Ирина Токарева on 12.12.2021.
//

import Foundation
import CoreBluetooth
import RxRelay
import RxSwift
import NetworkExtension
import StepsProcessor

struct Measurment: IMUInput {
    let ax: Float
    let ay: Float
    let az: Float
    let gx: Float
    let gy: Float
    let gz: Float
}

protocol DeviceControlVMProtocol {
    var isPeripheralConnected: BehaviorRelay<Bool> { get }
    var measurments: BehaviorRelay<[Measurment]> { get }
    var errorRelay: PublishRelay<String> { get }
    var downloadProgressRelay: PublishRelay<Progress> { get }
    
    func viewDidAppear()
    func viewDidDisappear()
    func startSampling()
    func endSampling()
    func beginCalibration()
    func setFrequency(freq: UInt16)
    func requestFile()
}

class DeviceControlVM: NSObject, DeviceControlVMProtocol {
    
    // MARK: - types
    typealias PeripheralCallback = () -> ()
    
    // MARK: - vars
    let errorRelay = PublishRelay<String>()
    let downloadProgressRelay = PublishRelay<Progress>()
    let isPeripheralConnected = BehaviorRelay<Bool>(value: false)
    let measurments = BehaviorRelay<[Measurment]>(value: [])
    
    private var sequenceNum: UInt16 = 0
    private var peripheral: CBPeripheral
    private var callback: PeripheralCallback?
    private var txCharacteristic: CBCharacteristic? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.isPeripheralConnected.accept(self?.txCharacteristic != nil)
            }
        }
    }
    private let disposeBag = DisposeBag()
    private let deviceApiService: DeviceApiService = DeviceApiServiceImpl.shared
    
    var ssid: String?
    var pass: String?
    
    // MARK: - initialiation
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        super.init()
        setupBindings()
    }
    
    // MARK: - methods
    func viewDidAppear() {
        BluetoothService.shared.connect(to: peripheral)
    }
    
    func viewDidDisappear() {
        BluetoothService.shared.cancellConnection(to: peripheral)
    }
    
    func startSampling() {
        let header = RequestHeader(size: 0, requestType: .startSampling, sequenceNumber: sequenceNum)
        let command = BasicComand(header: header)
        send(command: command)
    }
    
    func endSampling() {
        let header = RequestHeader(size: 0, requestType: .endSampling, sequenceNumber: sequenceNum)
        let command = BasicComand(header: header)
        send(command: command)
    }
    
    func beginCalibration() {
        let header = RequestHeader(size: 0, requestType: .beginCalibration, sequenceNumber: sequenceNum)
        let command = BasicComand(header: header)
        send(command: command)
    }
    
    func setFrequency(freq: UInt16) {
        let header = RequestHeader(size: 0, requestType: .setFrequency, sequenceNumber: sequenceNum)
        let command = SetFrequencyCommand(header: header, freq: freq)
        send(command: command)
    }
    
    func requestFile() {
        let header = RequestHeader(size: 0, requestType: .requestFileTransfer, sequenceNumber: sequenceNum)
        let command = BasicComand(header: header)
        send(command: command)
    }
    
    private func setupBindings() {
        BluetoothService.shared.peripheralConnectionRelay
            .subscribe(
                onNext: { [weak self] peripheral in
                    peripheral?.delegate = self
                    peripheral?.discoverServices(nil)
                    peripheral?.readRSSI()
                    if peripheral == nil {
                        self?.txCharacteristic = nil
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func send(command: CommandProtocol) {
        let data = command.packedWithCRC
        guard
            isPeripheralConnected.value,
            let characteristic = txCharacteristic
        else {
            return
        }
        peripheral.writeValue(Data(data), for: characteristic, type: .withResponse)
        sequenceNum += 1
    }
    
    private func process(response: [UInt8]) {
        guard
            let responseSize = response.first,
            response.count == 5 + 4 + responseSize
        else{
            return
        }
        guard let answerType = AnswerType(rawValue: response[1]) else {
            return
        }
        
        let request = RequestType(rawValue: response[2])
        
        switch answerType {
        case .ok:
            break
        case .ssid:
            let ssidData = response.suffix(from: 5).prefix(Int(responseSize))
            ssid = String(data: Data(ssidData), encoding: .utf8)
        case .password:
            let passData = response.suffix(from: 5).prefix(Int(responseSize))
            pass = String(data: Data(passData), encoding: .utf8)
            connectToWifi()
        case .state:
            break
        case .error:
            if request == .requestFileTransfer {
                downloadMeasurmentFile()
            } else {
                errorRelay.accept("Ошибка коммуникации")
            }
        }
        
        let string = response.map { String(format: "%02X", $0) }.joined(separator: "-")
        print("Got value:", string)
    }
    
    private func connectToWifi() {
        guard let ssid = ssid, let pass = pass else {
            return
        }

        let configuration = NEHotspotConfiguration(ssid: ssid, passphrase: pass, isWEP: false)
        NEHotspotConfigurationManager.shared.apply(configuration, completionHandler: { [weak self] error in
            if let error = error {
                if let neError = NEHotspotConfigurationError(rawValue: (error as NSError).code), neError == .alreadyAssociated {
                    self?.downloadMeasurmentFile()
                    return
                }
                self?.errorRelay.accept(error.localizedDescription)
            }
            self?.downloadMeasurmentFile()
        })
        print("Connecting to", ssid, pass)
    }
    
    private func downloadMeasurmentFile() {
        
        deviceApiService.fetchMeasurmentFile()
            .subscribe(
                onNext: { [weak self] progressData in
                    
                    switch progressData {
                    case let .prograss(progress):
                        self?.downloadProgressRelay.accept(progress)
                    case let .data(data):
                        self?.processMeasurmentFile(file: data)
                    }
                },
                onError: { [weak self] error in
                    self?.errorRelay.accept(error.localizedDescription)
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func processMeasurmentFile(file: Data) {
        let mesurmentSize = MemoryLayout<Float>.size * 6
        let measurmentsCount = file.count / mesurmentSize
        let data = [UInt8](file)
        var measurments = [Measurment]()
        for i in 0..<measurmentsCount {
            let rawMeaurment = Array(data.suffix(from: i * mesurmentSize).prefix(mesurmentSize))
            let f = convert(length: rawMeaurment.count, data: rawMeaurment, Float.self)
            let measurment = Measurment(
                ax: f[0],
                ay: f[1],
                az: f[2],
                gx: f[3],
                gy: f[4],
                gz: f[5]
            )
            measurments.append(measurment)
        }
        self.measurments.accept(measurments)
    }
    
    private func convert<T>(length: Int, data: UnsafePointer<UInt8>, _: T.Type) -> [T] {
        let numItems = length/MemoryLayout<T>.stride
        let buffer = data.withMemoryRebound(to: T.self, capacity: numItems) {
            UnsafeBufferPointer(start: $0, count: numItems)
        }
        return Array(buffer)
    }
}

// MARK: - CBPeripheralDelegate
extension DeviceControlVM: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard
            error == nil,
            let services = peripheral.services,
            let service = services.first(where: { $0.uuid == BluetoothService.Constants.serviceUUID })
        else {
            print("Can`t discover services")
            return
        }
        print("Peripheral discovered", services.count, "services")
        peripheral.discoverCharacteristics(nil, for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard
            error == nil,
            service.uuid == BluetoothService.Constants.serviceUUID,
            let characteristics = service.characteristics
        else {
            print("Can`t read value from characteristic")
            return
        }
        print("Peripheral discovered", characteristics.count, "characteristics")
        
        txCharacteristic = characteristics.first(where: { $0.uuid == BluetoothService.Constants.txCaracreristicUUID })
        
        if let characteristic = characteristics.first(where: { $0.uuid == BluetoothService.Constants.rxCaracreristicUUID }) {
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard
            error == nil,
            characteristic.uuid == BluetoothService.Constants.rxCaracreristicUUID,
            let data = characteristic.value
        else {
            print("Can`t read updated value from characteristic")
            return
        }
        
        let bytes = [UInt8](data)
        process(response: bytes)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            return
        }
    }
}

protocol CommandProtocol {
    var packedWithCRC: [UInt8] { get }
}

// MARK: - type
private extension DeviceControlVM {
    
    struct CRC32 {
        static var table: [UInt32] = {
            (0...255).map { i -> UInt32 in
                (0..<8).reduce(UInt32(i), { c, _ in
                    (c % 2 == 0) ? (c >> 1) : (0xEDB88320 ^ (c >> 1))
                })
            }
        }()

        static func checksum(bytes: [UInt8]) -> UInt32 {
            return ~(bytes.reduce(~UInt32(0), { crc, byte in
                (crc >> 8) ^ table[(Int(crc) ^ Int(byte)) & 0xFF]
            }))
        }
    }

    enum AnswerType: UInt8 {
        case ok = 0
        case ssid = 1
        case password = 2
        case state = 3
        case error = 255
    }
    
    enum RequestType: UInt8 {
        case startSampling = 1
        case endSampling = 2
        case beginCalibration = 3
        case setFrequency = 4
        case requestFileTransfer = 5
    }

    struct RequestHeader {
        var size: UInt8
        var requestType: RequestType
        var sequenceNumber: UInt16
        
        var packed: [UInt8] {
            return [size, requestType.rawValue] + withUnsafeBytes(of: sequenceNumber.littleEndian, Array.init)
        }
    }

    class BasicComand: CommandProtocol {
        var header: RequestHeader
        var randomNumber: UInt16 {
            .random(in: 0..<UInt16.max)
        }
        
        var packed: [UInt8] {
            header.size += UInt8(MemoryLayout<UInt16>.size & 0xFF)
            return header.packed
        }
        
        var packedWithRandomNum: [UInt8] {
            return packed + withUnsafeBytes(of: randomNumber.littleEndian, Array.init)
        }
        
        var packedWithCRC: [UInt8] {
            var data = packedWithRandomNum
            let crc = CRC32.checksum(bytes: data)
            data += withUnsafeBytes(of: crc.littleEndian, Array.init)
            return data
        }
        
        init(header: RequestHeader) {
            self.header = header
        }
    }

    class SetFrequencyCommand: BasicComand {
        
        let freq: UInt16
        
        override var packed: [UInt8] {
            header.size = UInt8(MemoryLayout<UInt16>.size & 0xFF)
            let data = super.packed
            return data + withUnsafeBytes(of: freq.littleEndian, Array.init)
        }
        
        init(header: RequestHeader, freq: UInt16) {
            self.freq = freq
            super.init(header: header)
        }
    }
}
