//
//  DeviceAPI.swift
//  app_part2
//
//  Created by Ирина Токарева on 26.03.2022.
//

import Moya
import Alamofire

enum DeviceAPI: TargetType {
    
    case measurmentFile
    
    var baseURL: URL {
        URL(string: "http://192.168.4.1")!
    }
    
    var path: String {
        switch self {
        case .measurmentFile:
            return "measurment"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .measurmentFile:
            return .get
        }
    }
    
    var task: Task {
        switch self {
        case .measurmentFile:
            return .downloadParameters(
                parameters: [:],
                encoding: URLEncoding.default,
                destination: DownloadRequest.suggestedDownloadDestination(options: .removePreviousFile)
            )
        }
    }
    
    var headers: [String : String]? {
        nil
    }
}
