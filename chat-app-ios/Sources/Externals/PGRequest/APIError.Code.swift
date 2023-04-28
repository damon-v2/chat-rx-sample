//
//  APIError.Code.swift
//
//  Created by ipagong on 16/10/2019.
//  Copyright © 2019 ipagong. All rights reserved.
//

import Foundation
extension APIError {
    public enum Code<ServiceCode> {
        case common(Common)
        case service(ServiceCode)
    }
}

extension APIError.Code {
    public enum Common: Int, Codable {
        case http = -9999
        case serviceExternalUnavailable
        case internalServerError
        case networkError
        case inconsistantModelParseFailed
        case opertaionCanceled
        case malformedRequest
        case unknownError
        case invalidDataFormat
        case globalException
    }
}

public struct APIAnonymousError: Error { }

