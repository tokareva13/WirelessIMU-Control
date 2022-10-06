//
//  MenuVM.swift
//  app_part2
//
//  Created by Ирина Токарева on 05.12.2021.
//

import Foundation
import UIKit

protocol MenuVMProtocol {
    var itemsPublisher: Published<[MenuItemVMProtocol]>.Publisher { get }
    var items: [MenuItemVMProtocol] { get }
    var view: UIViewController? { get set }
    
    func didSelectItem(at index: Int)
}

class MenuVM: MenuVMProtocol {

    // MARK: - vars
    var itemsPublisher: Published<[MenuItemVMProtocol]>.Publisher {
        $privateItems
    }
    var items: [MenuItemVMProtocol] {
        privateItems
    }
    
    weak var view: UIViewController?
    
    @Published
    private var privateItems: [MenuItemVMProtocol]
    
    // MARK: - inititialization
    init() {
        self.privateItems = []
        generateItems()
    }
    
    // MARK: - methods
    func didSelectItem(at index: Int) {
        let vc: UIViewController?
        switch index {
        case 0:
            let viewModel = PacientInfoEntryVM(coreDataService: CoreDataServiceImpl())
            vc = PacientInfoEditorVC(viewModel: viewModel)
        case 1:
            let viewModel = DeviceScanVM()
            vc = DeviceScannerVC(viewModel: viewModel)
        default:
            vc = nil
        }
        
        guard let vc = vc else { return }
        view?.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func generateItems() {
        privateItems = [
            MenuItemVM(image: UIImage(named: "img_blank"), title: "Заполнить анкету пациента"),
            MenuItemVM(image: UIImage(named: "img_modul"), title: "Подключить модуль")
            //MenuItemVM(image: UIImage(named: "img_research"), title: "Начать исследование"),
            //MenuItemVM(image: UIImage(named: "img_processing"), title: "Обработать данные")
        ]
    }
}
