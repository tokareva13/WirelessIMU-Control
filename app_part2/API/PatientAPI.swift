//
//  PatientAPI.swift
//  app_part2
//
//  Created by Ирина Токарева on 19.03.2022.
//

import Foundation
import Moya

enum PatientAPI: TargetType {
    
    case addPacient(info: PacientInfo)
    case showIMU(imuType: IMURawType, id: Int)
    case showPacient(id: Int)
    case showPacientsList
    
    
    var baseURL: URL {
        URL(string: "http://f0636538.xsph.ru/")!
    }
    
    var path: String {
        switch self {
        case .addPacient:
            return "index.php/"
        case .showIMU,
             .showPacient,
             .showPacientsList:
            return "api/"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .addPacient:
            return .post
        case .showIMU,
             .showPacient,
             .showPacientsList:
            return .get
        }
    }
    
    var task: Task {
        
        var requestParameters: [String: Any] = [
            "secret_key": "123",
        ]
        
        switch self {
        case let .addPacient(info):
            requestParameters["method"] = "add"
            requestParameters["ok"] = "Remove this shit ASAP"
            requestParameters = requestParameters.merging(info.toUrlParameters()) { _, new in
                return new
            }
        case let .showPacient(id):
            requestParameters["method"] = "patient_show"
            requestParameters["id"] = id
        case .showPacientsList:
            requestParameters["method"] = "show"
        case let .showIMU(type, id):
            requestParameters["method"] = type.apiMethod
            requestParameters["id"] = id
        }
        
        return .requestParameters(
            parameters: requestParameters,
            encoding: URLEncoding.default
        )
    }
    
    var headers: [String : String]? {
        return nil
    }
}

extension PatientAPI {
    
    enum IMURawType {
        case accel
        case gyro
        case compass
        case temp
        
        fileprivate var apiMethod: String {
            switch self {
            case .accel:
                return "axel_show"
            case .gyro:
                return "gyro_show"
            case .compass:
                return "magn_show"
            case .temp:
                return "temp_show"
            }
        }
    }
}
