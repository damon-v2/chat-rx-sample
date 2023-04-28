//
//  Model.Message.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/26.
//

import Foundation

extension Model {
    enum Chat {
        case message(Model.Chat.Message)
        case file(Model.Chat.File)
    }
}

extension Model.Chat {
    var id: String? {
        switch self {
        case .file(let data): return data.id
        case .message(let data): return data.id
        }
    }
    
    var senderId: String? {
        switch self {
        case .file(let data): return data.sender
        case .message(let data): return data.sender
        }
    }
    
    var original: Any? {
        switch self {
        case .file(let data): return data.original
        case .message(let data): return data.original
        }
    }
}

extension Model.Chat {
    struct Message {
        let id: String
        let message: String
        let sender: String
        let nickname: String
        let original: Any
    }
    
    struct File {
        let id: String
        let fileURL: String
        let fileType: String
        let sender: String
        let nickname: String
        let original: Any
    }
}

import RxDataSources

extension Model.Chat {
    enum SenderType {
        case my
        case other
    }
}

extension Model.Chat {
    struct Section: SectionModelType {
        var count: Int { items.count }
        var items: [Model.Chat]
    }
}

extension Model.Chat.Section {
    init(original: Model.Chat.Section, items: [Model.Chat]) {
        self = original
        self.items = items
    }
}
