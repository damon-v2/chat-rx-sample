//
//  Model+Chat.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/25.
//

import Foundation
import SendbirdChatSDK

typealias ChatUser = SendbirdChatSDK.User
typealias ChatChannel = SendbirdChatSDK.GroupChannel

typealias ChatMessage = SendbirdChatSDK.UserMessage
typealias ChatFile = SendbirdChatSDK.FileMessage

extension Model.User {
    init?(original: Any?) {
        guard let chatUser = original as? ChatUser else { return nil }
        
        self.id = chatUser.id
        self.userId = chatUser.userId
        self.nickname = chatUser.nickname
        self.profileURL = chatUser.profileURL
        self.original = chatUser
    }
}
 
extension Model.Channel {
    init?(original: Any?) {
        guard let channel = original as? ChatChannel else { return nil }
        
        self.id = channel.id
        self.name = channel.name
        self.lastMessage = channel.lastMessage is FileMessage ? "{IMAGE_MESSAGE...}" : channel.lastMessage?.message ?? ""
        
        self.original = channel
    }
}

extension Model.Channel.Create {
    func transform() -> SendbirdChatSDK.GroupChannelCreateParams {
        let params = SendbirdChatSDK.GroupChannelCreateParams()
        params.name = self.name
        params.userIds = self.userList ?? []
        return params
    }
    
}

extension Model.Chat {
    init?(original: Any?) {
        guard let message = original as? BaseMessage else { return nil }
        guard let sender = message.sender else { return nil }
        
        switch message {
        case let data as ChatMessage:
            self = .message(.init(id: data.id.description,
                                  message: data.message,
                                  sender: sender.userId,
                                  nickname: sender.nickname.isEmpty ? sender.userId : sender.nickname,
                                  original: data))
            return
        case let data as ChatFile:
            self = .file(.init(id: data.id.description,
                               fileURL: data.url,
                               fileType: data.type,
                               sender: sender.userId,
                               nickname: sender.nickname.isEmpty ? sender.userId : sender.nickname,
                               original: data))
            return
        default:
            return nil
        }
    }
    
    func isOthers(_ userId: String? = AuthService.instance.userId) -> Model.Chat.SenderType {
        userId.isSome && userId == self.senderId ? .my : .other
    }
}
