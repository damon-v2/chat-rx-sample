//
//  Keychain+Service.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import Foundation
import KeychainAccess

extension Keychain {
    enum Service: String {
        case userId
    }
}

extension Keychain.Service {
    static var instance: Keychain { Keychain(service: Bundle.main.bundleIdentifier!) }
    
    func get() -> String? {
        try? Keychain.Service.instance.get(self.rawValue)
    }
    
    func set(_ value: String) {
        try? Keychain.Service.instance.set(value, key: self.rawValue)
    }
    
    func remove() {
        try? Keychain.Service.instance.remove(self.rawValue)
    }
}
