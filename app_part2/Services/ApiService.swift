//
//  ApiService.swift
//  app_part2
//
//  Created by Ирина Токарева on 19.03.2022.
//

import Foundation
import RxSwift
import Moya

protocol ApiService {
    
    func addPacient(with info: PacientInfo) -> Single<Void>
    func showPacient(with id: Int) -> Single<PacientInfo>
    func showIMU(of userId: Int, type: PatientAPI.IMURawType) -> Single<Void>
    func showPacientsList() -> Single<[String: PacientInfo]>
}

class ApiServiceImpl: ApiService {
    
    // MARK: - vars
    
    static let shared = ApiServiceImpl()
    private let provider = MoyaProvider<PatientAPI>()
    
    // MARK: - methods
    
    func addPacient(with info: PacientInfo) -> Single<Void> {
        provider.rx
            .request(.addPacient(info: info))
            .map { response in
                guard response.statusCode == 200 else {
                    throw NSError(domain: "Неверный результирующий код", code: response.statusCode, userInfo: nil)
                }
            }
    }
    
    func showPacient(with id: Int) -> Single<PacientInfo> {
        provider.rx
            .request(.showPacient(id: id))
            .map { result -> PacientInfo in
                return try JSONDecoder().decode(PacientInfo.self, fromShitty: result.data)
            }
    }
    
    func showIMU(of userId: Int, type: PatientAPI.IMURawType) -> Single<Void> {
        provider.rx
            .request(.showIMU(imuType: type, id: userId))
            .map { _ in }
    }
    
    func showPacientsList() -> Single<[String : PacientInfo]> {
        provider.rx
            .request(.showPacientsList)
            .map { response -> [String : PacientInfo] in
                return try JSONDecoder().decode([String : PacientInfo].self, fromShitty: response.data)
            }
    }
}
