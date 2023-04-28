//
//  API.Parameter.swift
//  BaseProject
//
//  Created by ipagong on 22/11/2019.
//  Copyright © 2019 ipagong. All rights reserved.
//

import Foundation

extension API {
    public enum Parameter {
        case map([String: Any?]?)
        case body(Encodable)
    }
}

extension API.Parameter {
    var params:[String: Any] {
        switch self {
        case .map(let dic):
            return dic?.compactMapValues{$0} ?? [:]
        case .body(let value):
            return value.toDictionary() ?? [:]
        }
    }
}

extension Encodable {
    fileprivate func toDictionary(keyStrategy strategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys, options: JSONSerialization.ReadingOptions = [.allowFragments]) -> [String: Any]? {
        let encoder = JSONEncoder()
        
        encoder.keyEncodingStrategy = strategy
        
        guard let data = try? encoder.encode(self) else { return nil }
        
        return (try? JSONSerialization.jsonObject(with: data, options: options)).flatMap { $0 as? [String: Any] }
    }
}

#if DEBUG
public var needPrintAPILog = true
#else
public var needPrintAPILog = false
#endif

func APILog(_ message:String) {
    guard needPrintAPILog == true else { return }
    print(message)
}

extension Data {
    public func parse<Element:Decodable>(keyStrategy strategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) throws -> Element {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = strategy
        return try decoder.decode(Element.self, from: self)
    }
    
    public func parseList<Element:Decodable>(keyStrategy strategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys) throws -> [Element] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = strategy
        
        return try decoder.decode([Element].self, from: self)
    }
}

#if canImport(SwiftyJSON)
import SwiftyJSON

extension Data {
    public func transformToJSON(key:String? = nil) throws -> JSON {
        return try {
            if self.isEmpty { return JSON(()) }
            let value = try JSON(data: self)
            return key == nil ? value : value[key!]
        }()
    }
    
    public func parse<V>(_ closure: ((JSON) throws -> V)) rethrows -> V {
        let json = try! self.transformToJSON()
        return try closure(json)
    }
}
#endif
