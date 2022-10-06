//
//  MenuItemVM.swift
//  app_part2
//
//  Created by Ирина Токарева on 05.12.2021.
//

import Foundation
import UIKit

protocol MenuItemVMProtocol {
    var image: UIImage? { get }
    var title: String { get }
}

struct MenuItemVM: MenuItemVMProtocol {
    var image: UIImage?
    var title: String
}
