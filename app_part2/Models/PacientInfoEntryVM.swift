//
//  PacientInfoEntryVM.swift
//  app_part1
//
//  Created by Ирина Токарева on 14.11.2021.
//

import Foundation
import RxSwift

protocol PacientInfoEntryVMProtocol {
    var itemsPublisher: Published<[Any]>.Publisher { get }
    var items: [Any] { get }
    
    func saveData() -> Single<Void>
}

class PacientInfoEntryVM: PacientInfoEntryVMProtocol {

    // MARK: - vars
    var itemsPublisher: Published<[Any]>.Publisher {
        $privateItems
    }
    var items: [Any] {
        privateItems
    }
    
    @Published
    private var privateItems: [Any]
    private let coreDataService: CoreDataService
    
    // MARK: - inititialization
    init(coreDataService: CoreDataService) {
        self.coreDataService = coreDataService
        self.privateItems = []
        generateItems()
    }
    
    // MARK: - methods
    
    func saveData() -> Single<Void> {
        
        let textEntryVMs = privateItems.compactMap {
            $0 as? TextEntryVMProtocol
        }
        
        guard
            let fullName = textEntryVMs[safe: 0]?.checkableText,
            let birhday = textEntryVMs[safe: 1]?.checkableText,
            let gender = textEntryVMs[safe: 2]?.checkableText,
            let weight = textEntryVMs[safe: 3]?.floatValue,
            let lenght = textEntryVMs[safe: 4]?.floatValue,
            let allergy = textEntryVMs[safe: 5]?.checkableText,
            let result = textEntryVMs[safe: 6]?.checkableText
        else {
            return .error(NSError(domain: "Не все поля заполнены!", code: 229, userInfo: nil))
        }
        
        let info = PacientInfo(
            fullName: fullName,
            gender: gender,
            birthday: birhday,
            lenght: lenght,
            mass: weight,
            result: result,
            alergy: allergy
        )
        
        return ApiServiceImpl.shared.addPacient(
            with: info
        )
    }
    
    private func generateItems() {
        privateItems = [
            ImageSelectionVM(title: "Анкета пациента", image: nil),
            TextEntryVM(labelText: "ФИО", placeholder: ""),
            TextEntryVM(labelText: "Дата рождения", placeholder: ""),
            TextEntryVM(labelText: "Пол", placeholder: ""),
            TextEntryVM(labelText: "Веc", placeholder: "", isHalfSized: true),
            TextEntryVM(labelText: "Рост", placeholder: "", isHalfSized: true),
            TextEntryVM(labelText: "Аллергические реации", placeholder: ""),
            TextEntryVM(labelText: "Диагноз", placeholder: "")
        ]
    }
}
