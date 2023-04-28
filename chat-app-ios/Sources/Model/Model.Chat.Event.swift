//
//  Model.Chat.Event.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/27.
//

import Foundation

extension Model.Chat {
    enum Event {
        case receive(Model.Channel, Model.Chat)
        case delete(Model.Channel, Int64)
    }
}

extension Model.Chat.Event {
    var channel: Model.Channel {
        switch self {
        case .receive(let channel, _): return channel
        case .delete(let channel, _): return channel
        }
    }
    
    func isValid(with channel: Model.Channel?) -> Bool {
        channel.isSome && self.channel.id == channel!.id
    }
    
    var newMessage: Model.Chat? {
        switch self {
        case .receive(_, let chat): return chat
        case .delete: return nil
        }
    }
    
    var deletedMessageId: Int64? {
        switch self {
        case .receive: return nil
        case .delete(_, let id): return id
        }
    }
}
