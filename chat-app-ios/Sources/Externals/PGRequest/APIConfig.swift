//
//  APIConfig.swift
//
//  Created by ipagong on 16/10/2019.
//  Copyright © 2019 ipagong. All rights reserved.
//

import Foundation
import Alamofire
import RxSwift

public struct API { }

public protocol APIConfig {
    associatedtype Response
    associatedtype ServerConfig: DomainConfig
    associatedtype ServiceError: ServiceErrorable
    
    static var domainConfig: ServerConfig.Type { get }
    static var serviceError: ServiceError.Type { get }
    
    var path: String { get }
    var method: Alamofire.HTTPMethod { get }
    var parameters: API.Parameter? { get }
    var encoding: ParameterEncoding { get }
    
    func parse(_: Data) throws -> Response
    func makeRequest() -> Observable<Self.Response>
    
    var debuggable: Bool { get }
}

public protocol DomainConfig {
    static var defaultHeader: [String: String]? { get }
    static var parameters: [String: Any?]? { get }
    static var manager: Alamofire.Session { get }
    static var domain: String { get }
}

public protocol APISpecifiedHeaderConfig {
    var headers: [String: String]? { get }
}

extension APIConfig {
    public func request() -> Observable<Self.Response> {
        return self.makeRequest()
            .globalException(self)
            .do(onError: { (error) in
                if self is APIErrorIgnorable { return }
                #if DEBUG
                (error as? APIError<ServiceError>)?.showMessagePopup()
                #endif
            })
    }
    
    public var debuggable: Bool { true }
}

extension APIConfig {
    internal var fullPath: String { return Self.domainConfig.domain + self.path }
    
    internal var debugFullPath: String {
        if API.Constant.hidepath == true { return "{server_domain}" + self.path }
        return Self.domainConfig.domain + self.path
    }
    
    internal var fullHeaders: [String: String] {
        return ((self as? APISpecifiedHeaderConfig)?.headers ?? [:])
            .reduce(into: Self.domainConfig.defaultHeader ?? [:]) { (result, element) in result[element.key] = element.value }
    }
    
    internal var fullParamaters: [String: Any]? {
        return (self.parameters?.params ?? [:])
            .reduce(into: (Self.domainConfig.parameters ?? [:]).compactMapValues{$0}) { (result, element) in result[element.key] = element.value }
    }
}

extension APIConfig {
    var encoding: ParameterEncoding {
        switch self.method {
        case .get:
            return URLEncoding.default
        default:
            return JSONEncoding.default
        }
    }
}
