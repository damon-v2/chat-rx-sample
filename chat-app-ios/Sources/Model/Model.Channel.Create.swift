//
//  Model.Channel.Params.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/26.
//

import Foundation

extension Model.Channel {
    struct Create {
        var name: String?
        var userList: [String]?
        
        var isValid: Bool {
            guard let name = self.name, name.count > 3 else { return false }
            guard let userList = self.userList, userList.count > 0 else { return false }
            return true
        }
        
        func update(name: String? = nil,
                    userList: [String]? = nil) -> Create {
            return .init(name: name ?? self.name,
                         userList: userList ?? self.userList)
        }
    }
}
