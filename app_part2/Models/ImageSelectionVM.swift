//
//  ImageSelectionVM.swift
//  app_part2
//
//  Created by Ирина Токарева on 28.11.2021.
//

import Foundation
import UIKit

protocol ImageSelectionVMProtocol {
    var title: String { get }
    var image: UIImage? { get set }
}

class ImageSelectionVM: ImageSelectionVMProtocol {
    
    // MARK: - vars
    let title: String
    var image: UIImage?
    
    // MARK: - initialization
    init(title: String, image: UIImage? = nil) {
        self.title = title
        self.image = image
    }
}
