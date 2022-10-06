//
//  JSONDecoder+shittyInput.swift
//  app_part2
//
//  Created by Ирина Токарева on 19.03.2022.
//

import Foundation

extension JSONDecoder {
    
    func decode<T: Decodable>(_ type: T.Type, fromShitty data: Data) throws -> T {
        guard
            let jsonString = String(data: data, encoding: .utf8),
            let startIndex = jsonString.firstIndex(of: "{")
        else {
            throw NSError(domain: "Cant parce data", code: 228)
        }
    
        let suffix = jsonString.suffix(from: startIndex)
        
        guard let data = suffix.data(using: .utf8) else {
            throw NSError(domain: "Cant parce data", code: 1488)
        }
        
        return try decode(type, from: data)
    }
}
