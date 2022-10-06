//
//  Array+safe.swift
//  app_part2
//
//  Created by Ирина Токарева on 19.03.2022.
//

import Foundation

extension Array {
    
    subscript(safe index: Index) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}
