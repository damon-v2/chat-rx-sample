//
//  APIConfig+Error.swift
//
//  Created by ipagong on 16/10/2019.
//  Copyright © 2019 ipagong. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

public protocol APIConfigWithError: APIConfig {
    associatedtype APISepecifedError: Error
    func catchError(_: APIError<ServiceError>) -> APISepecifedError?
}

public protocol APIErrorIgnorable  { }

extension APIConfigWithError {
    public func requestWithCatch() -> Observable<Swift.Result<Self.Response, Self.APISepecifedError>> {
        return self.makeRequest()
            .map(Swift.Result<Self.Response, Self.APISepecifedError>.success)
            .catchError { (error) -> Observable<Swift.Result<Self.Response, Self.APISepecifedError>> in
                guard let apiError = error as? APIError<ServiceError> else { throw error }
                guard let serviceError = self.catchError(apiError) else { throw error }
                
                return Observable.just(Swift.Result<Self.Response, Self.APISepecifedError>.failure(serviceError))
                
        }.do(onError: { (error) in (error as? APIError<ServiceError>)?.showMessagePopup() })
    }
}

extension Swift.Result {
    public func mapData<V>(_ closure: (Success) -> V) -> Swift.Result<V, Failure> {
        switch self {
        case .success(let data):
            return Swift.Result<V, Failure>.success(closure(data))
        case .failure(let error):
            return .failure(error)
        }
    }
    
    public func mapError<E2>(_ closure: (Failure) -> E2) -> Swift.Result<Success, E2> where E2: Error {
        switch self {
        case .success(let data):
            return .success(data)
        case .failure(let error):
            return Swift.Result<Success, E2>.failure(closure(error))
        }
    }
}
