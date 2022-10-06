//
//  PacientInfo.swift
//  app_part2
//
//  Created by Ирина Токарева on 19.03.2022.
//

import Foundation

struct PacientInfo: Decodable {
    
    let fullName: String
    let gender: String
    let birthday: String
    let lenght: Float
    let mass: Float
    let result: String
    let alergy: String
    
    enum CodingKeys: String, CodingKey {
        case fullName = "name"
        case gender = "polis"
        case birthday
        case lenght = "high"
        case mass
        case result = "diagnoz"
        case alergy = "allerg"
    }
}

extension PacientInfo {
    
    func toUrlParameters() -> [String: Any] {
        var urlParameters = [CodingKeys: Any]()
        
        urlParameters[.fullName] = fullName
        urlParameters[.gender] = gender
        urlParameters[.birthday] = birthday
        urlParameters[.lenght] = lenght
        urlParameters[.mass] = mass
        urlParameters[.result] = result
        urlParameters[.alergy] = alergy
        
        return urlParameters.reduce(into: [String: Any]()) {
            $0[$1.key.rawValue] = $1.value
        }
    }
}
