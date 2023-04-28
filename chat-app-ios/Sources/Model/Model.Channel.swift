//
//  Model.Room.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/25.
//

import Foundation

extension Model {
    struct Channel {
        let id: String
        let name: String
        let lastMessage: String
        let original: Any
    }
}

import RxDataSources

extension Model.Channel {
    struct Section: SectionModelType {
        var count: Int { items.count }
        var items: [Model.Channel]
    }
}

extension Model.Channel.Section {
    init(original: Model.Channel.Section, items: [Model.Channel]) {
        self = original
        self.items = items
    }
}
