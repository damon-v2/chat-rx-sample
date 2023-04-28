//
//  APIErrorable.swift
//
//  Created by ipagong on 16/10/2019.
//  Copyright © 2019 ipagong. All rights reserved.
//

import UIKit

public protocol ServiceErrorable: Codable {
    associatedtype Code: ServiceErrorCodeRawPresentable
    
    func getCode() -> Code
    func getMessage() -> String
    
    static func getKeyDecodingStrategy() -> JSONDecoder.KeyDecodingStrategy
    static func globalExeception(with error: APIError<Self>) -> Bool
}

extension ServiceErrorable {
    public static func getKeyDecodingStrategy() -> JSONDecoder.KeyDecodingStrategy { .useDefaultKeys }
}

public protocol ServiceErrorCodeRawPresentable: Codable {
    var rawValue:Int { get }
}

public struct APIError<ServiceError: ServiceErrorable>: Swift.Error {
    public let code: Code<ServiceError.Code>
    public let status: Int?
    public let message: String?

    public init(code: Code<ServiceError.Code>, status: Int? = nil, message:String? = nil) {
        self.code    = code
        self.status  = status
        self.message = message
    }
    
    internal init(data: Data, status: Int? = nil, type:ServiceError.Type) throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = ServiceError.getKeyDecodingStrategy()
        let service = try decoder.decode(ServiceError.self, from: data)
        
        self.code = APIError.Code.service(service.getCode())
        self.message = service.getMessage()
        self.status = status
    }
    
    var localizedDescription: String {
        switch self.code {
        case .common(let error): return self.message ?? "API ErrorCode: \(error.rawValue)"
        case .service(let error): return self.message ?? "Service ErrorCode: \(error.rawValue)"
        }
    }
}

extension APIError {
    func showMessagePopup() {
        let alert = UIAlertController(title: nil, message: self.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .cancel, handler: nil))
        
        self.target?.present(alert, animated: true, completion: nil)
    }
    
    fileprivate var target:UIViewController? {
        guard let rootVc = UIApplication.shared.windows.first?.rootViewController else { return nil }
        
        var top = rootVc
        
        while let newTop = top.presentedViewController { top = newTop }
        
        guard let last = top.children.last else { return top }
        
        return last
    }
}
