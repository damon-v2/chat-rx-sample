//
//  APIConfig+Upload.swift
//
//  Created by ipagong on 16/10/2019.
//  Copyright © 2019 ipagong. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import Alamofire

public protocol APIUploadConfig: APIConfig {
    var formData: [UploadDatable] { get }
}

public enum APIUploadStatus<Result> {
    case progress(Progress)
    case complete(Result)
}

public protocol UploadDatable {
    var data: Data { get }
    var fileName: String { get }
    var withName: String { get }
    var mime: String { get }
}

public struct DefaultUploadData: UploadDatable {
    public let data:Data
    public let fileName:String
    public let withName:String
    public let mimeType:MimeType
    
    public var mime: String { self.mimeType.rawValue }
    
    public enum MimeType: String {
        case png = "image/png"
        case jpg = "image/jpeg"
    }
    
    public init(data:Data, fileName:String, withName:String, mimeType:MimeType) {
        self.data = data
        self.fileName = fileName
        self.withName = withName
        self.mimeType = mimeType
    }
}

extension APIUploadConfig {
    public func makeRequest() -> Observable<Self.Response> {
        return Observable<Response>.create { (observer: AnyObserver<Response>) -> Disposable in
            
            APILog("\n\n")
            APILog("<----------- UPLOAD ------------>")
            APILog("")
            APILog("**** fullpath: \(self.debugFullPath)")
            APILog("")
            APILog("<------------------------------->")
            APILog("\n")
            
            let request = Self.domainConfig.manager.upload(multipartFormData: self.multiPartFormData(),
                                                           to: self.fullPath,
                                                           usingThreshold: MultipartFormData.encodingMemoryThreshold,
                                                           method: self.method,
                                                           headers: HTTPHeaders(self.fullHeaders))
                
            request
                .validate()
                .responseData(completionHandler: self.responseHandler(observer))

            return Disposables.create { request.cancel() }
        }
    }
}

extension APIUploadConfig {
    fileprivate func multiPartFormData() -> ((MultipartFormData) -> Void) {
        return { (form:MultipartFormData) -> Void in
            self.fullParamaters?.forEach{ (key, value) in
                if let data = (value as? CustomStringConvertible)?.description.data(using: .utf8) {
                    form.append(data, withName: key)
                }
            }
            self.formData.forEach{ form.append($0.data,
                                               withName: $0.withName,
                                               fileName: $0.fileName,
                                               mimeType: $0.mime) }
        }
    }
}
