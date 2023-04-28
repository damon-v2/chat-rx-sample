//
//  Model.User.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/25.
//

import Foundation

extension Model {
    struct User {
        let id: String
        let userId: String
        
        let nickname: String
        let profileURL: String?
        
        let original: Any
        
        var userIdAndNickname: String {
            [self.userId, nickname.count > 0 ? " (\(nickname))" : ""].joined()
        }
    }
}

extension Model.User: Hashable {
    static func == (lhs: Model.User, rhs: Model.User) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(self.id) }
}

import RxDataSources


extension Model.User {
    struct Section: SectionModelType {
        var count: Int { items.count }
        var items: [Model.User]
    }
}

extension Model.User.Section {
    init(original: Model.User.Section, items: [Model.User]) {
        self = original
        self.items = items
    }
}
