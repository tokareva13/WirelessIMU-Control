//
//  DeviceApiService.swift
//  app_part2
//
//  Created by Ирина Токарева on 26.03.2022.
//

import Foundation
import Moya
import RxSwift

enum DeviceDownloadState {
    case prograss(Progress)
    case data(Data)
}

protocol DeviceApiService {
    func fetchMeasurmentFile() -> Observable<DeviceDownloadState>
}

class DeviceApiServiceImpl: DeviceApiService {
    
    static let shared = DeviceApiServiceImpl()
    
    private let provider = MoyaProvider<DeviceAPI>()
    
    func fetchMeasurmentFile() -> Observable<DeviceDownloadState> {
        
        provider.rx.requestWithProgress(
            .measurmentFile,
            callbackQueue: .global(qos: .userInitiated)
        ).map { prograssData -> DeviceDownloadState in
            guard prograssData.completed else {
                return .prograss(prograssData.progressObject ?? Progress())
            }
            
            guard let response = prograssData.response else {
                throw NSError(
                    domain: "Ошибка загрузка файла",
                    code: -1,
                    userInfo: nil
                )
            }
            
            let directoryURLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            
            guard
                response.statusCode == 200,
                let suggestedFilename = response.response?.suggestedFilename,
                let url = directoryURLs.first?.appendingPathComponent(suggestedFilename)
            else {
                throw NSError(
                    domain: "Ошибка загрузка файла",
                    code: response.statusCode,
                    userInfo: nil
                )
            }
            
            guard let data = try? Data(contentsOf: url) else {
                throw NSError(
                    domain: "Невозможно прочитать файл измерения",
                    code: -2,
                    userInfo: nil
                )
            }
            
            return .data(data)
        }
    }
}
