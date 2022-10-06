//
//  ReusableCellProtocol.swift
//  app_part2
//
//  Created by Ирина Токарева on 19.10.2021.
//

import UIKit

protocol ReusableCellProtocol {
    static var reuseIdentificator: String { get }
}

extension UITableViewCell: ReusableCellProtocol {
    class var reuseIdentificator: String {
        String(describing: self)
    }
}

extension UICollectionViewCell: ReusableCellProtocol {
    class var reuseIdentificator: String {
        String(describing: self)
    }
}
