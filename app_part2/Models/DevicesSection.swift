//
//  DevicesSection.swift
//  app_part2
//
//  Created by Ирина Токарева on 12.12.2021.
//

import Foundation
import RxDataSources

struct DevicesSection {
    var header: String
    var items: [Item]
}

extension DevicesSection: AnimatableSectionModelType {
    typealias Item = DeviceCellVM

    var identity: String {
        header
    }
    
    
    init(original: DevicesSection, items: [Item]) {
       self = original
       self.items = items
    }
}
