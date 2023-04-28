//
//  UserDefaults+Cacheable.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import Foundation

protocol Cacheable {
    associatedtype Data : Codable
    static var value:Data? { get set }
}

extension Cacheable {
    static var cacheKey:String { return String(describing: self) }
    static var value:Data? {
        set {
            try? UserDefaults.standard.set(object: newValue, forKey: self.cacheKey)
            UserDefaults.standard.synchronize()
        }
        
        get {
            return (try? UserDefaults.standard.get(objectType: Data.self, forKey: self.cacheKey)) ?? nil
        }
    }
}
