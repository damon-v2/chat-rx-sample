//
//  ChatService.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import Foundation
import SendbirdChatSDK
import RxSwift
import RxCocoa

class ChatService {
    static let instance = ChatService()
    
    private var userListQuery: SendbirdChatSDK.ApplicationUserListQuery?
    private var groupChannelQuery: SendbirdChatSDK.GroupChannelListQuery?
    
    private var messageQueries = Dictionary<String, SendbirdChatSDK.PreviousMessageListQuery>()
    
    // TODO: *** UPDATE_APP_ID ***
    private let appId = "APP_ID"
    
    func setup(handler: @escaping () -> (Void)) {
        let params = InitParams(applicationId: appId,
                                isLocalCachingEnabled: true,
                                logLevel: .debug)
        SendbirdChat.initialize(params: params, completionHandler:  { error in
            debugPrint(error?.localizedDescription ?? "SendbirdChat setup succeed.")
            handler()
        })
    }
    
    func createRoom(name: String, userIds: [String]) -> Observable<Result<Model.Channel, Error>> {
        return Observable.create { observer in
            let params = GroupChannelCreateParams()
            params.name = name
            params.userIds = userIds
            
            SendbirdChatSDK.GroupChannel.createChannel(params: params) { channel, error in
                guard let channel = Model.Channel.init(original: channel) else {
                    observer.onNext(.failure(error ?? NSError()))
                    observer.onCompleted()
                    return
                }
                
                observer.onNext(.success(channel))
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func getUserList(refresh: Bool = false) -> Observable<[Model.User]> {
        return Observable<[Model.User]>.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            if self.userListQuery == nil || refresh == true {
                self.userListQuery = SendbirdChat.createApplicationUserListQuery{ params in
                    params.limit = Constant.userLimit
                }
            }
            
            self.userListQuery?.loadNextPage { [weak self] users, error in
                guard let query = self?.userListQuery else { return }
                
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                observer.onNext(users?.compactMap(Model.User.init(original:)) ?? [])
                
                if query.hasNext == false {
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    func getGroupChannelList(refresh: Bool = false) -> Observable<[Model.Channel]> {
        return Observable<[Model.Channel]>.create { [weak self] observer in
            guard let self = self else { return Disposables.create() }
            
            if self.groupChannelQuery == nil || refresh == true {
                self.groupChannelQuery = SendbirdChatSDK.GroupChannel.createMyGroupChannelListQuery(paramsBuilder: { params in
                    params.limit = Constant.channelLimit
                    params.order = .latestLastMessage
                })
            }
            
            self.groupChannelQuery?.loadNextPage { [weak self] users, error in
                guard let query = self?.groupChannelQuery else { return }
                
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                observer.onNext(users?.compactMap(Model.Channel.init(original:)) ?? [])
                
                if query.hasNext == false {
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    func createChannel(with model: Model.Channel.Create) -> Observable<Model.Channel> {
        guard model.isValid == true else { return .empty() }
        
        return Observable.create { observer in
            SendbirdChatSDK.GroupChannel.createChannel(params: model.transform()) { channel, error in
                if let error = error {
                    observer.onError(error)
                    return
                }

                guard let channel = Model.Channel(original: channel) else {
                    observer.onError(NSError())
                    return
                }
                
                observer.onNext(channel)
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func getMessages(with data: Model.Channel?, refresh: Bool = true) -> Observable<[Model.Chat]> {
        guard let channel = data?.original as? SendbirdChatSDK.GroupChannel else { return .empty() }
        
        return Observable<[Model.Chat]>.create { [weak self, weak channel] observer in
            guard let self = self, let channel = channel else {
                return Disposables.create()
            }
            
            guard let query = self.createMessageQuery(channel: channel, refresh: refresh) else {
                return Disposables.create()
            }
            
            self.messageQueries[channel.id] = query
            
            query.loadNextPage { [weak query] messages, error in
                guard let query = query else { return }
                
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                
                let chatList = messages?.compactMap(Model.Chat.init(original:)) ?? []
                debugPrint(chatList.count)
                observer.onNext(chatList)
                
                if query.hasNext == false {
                    observer.onCompleted()
                }
            }
            
            return Disposables.create()
        }
    }
    
    func sendMessage(with data: Model.Channel?, message: String) -> Observable<Model.Chat> {
        guard let channel = data?.original as? SendbirdChatSDK.GroupChannel else { return .empty() }
        
        return Observable<Model.Chat>.create { [weak channel] observer in
            guard let channel = channel else {
                return Disposables.create()
            }
            
            channel.sendUserMessage(message) { message, error in
                if let error = error {
                    observer.onError(error)
                }
                
                if let chat = Model.Chat(original: message) {
                    observer.onNext(chat)
                }
                
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func sendImage(with data: Model.Channel?, image: UIImage) -> Observable<Model.Chat> {
        guard let channel = data?.original as? SendbirdChatSDK.GroupChannel else { return .empty() }
        
        return Observable<Model.Chat>.create { [weak channel] observer in
            guard let channel = channel else {
                return Disposables.create()
            }
            
            guard let data = image.pngData() else {
                return Disposables.create()
            }
            
            channel.sendFileMessage(params: FileMessageCreateParams(file: data)) { message, error in
                if let error = error {
                    observer.onError(error)
                }
                
                if let chat = Model.Chat(original: message) {
                    observer.onNext(chat)
                }
                
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func confirmAndDeleteMessage(target: UIViewController?, channel: Model.Channel?, chat: Model.Chat) -> Observable<String> {
        guard let target = target else { return .empty() }
        return UIAlertController.rx.show(in: target,
                                         title: "DELETE IT?",
                                         message: nil,
                                         buttons: [.cancel("CANCEL"), .default("CONFIRM")])
        .asObservable().filter{ $0 == 1 }.collapseType()
        .flatMapLatest{ ChatService.instance.deleteMessage(channel: channel, chat: chat) }
    }
    
    func deleteMessage(channel: Model.Channel?, chat: Model.Chat) -> Observable<String> {
        guard let channel = channel?.original as? SendbirdChatSDK.GroupChannel else { return .empty() }
        
        return Observable<String>.create { [weak channel] observer in
            guard let channel = channel else { return Disposables.create() }
            
            guard let id = chat.id, let message = chat.original as? BaseMessage else { return Disposables.create() }
            
            channel.deleteMessage(message) { error in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onNext(id)
                }
                
                observer.onCompleted()
                
            }
            return Disposables.create()
        }
    }
}


// private extension
extension ChatService {
    private func createMessageQuery(channel: ChatChannel, refresh: Bool) -> SendbirdChatSDK.PreviousMessageListQuery? {
        if refresh == true { return channel.createPreviousMessageListQuery(params: .default) }
        return self.messageQueries[channel.id] ?? channel.createPreviousMessageListQuery(params: .default)
    }
}

extension PreviousMessageListQueryParams {
    static var `default`: PreviousMessageListQueryParams {
        let params = PreviousMessageListQueryParams()
        params.limit = ChatService.Constant.messageLimit
        params.reverse = true
        return params
    }
}

extension ChatService {
    class ChannelEventReceiver: SendbirdChatSDK.GroupChannelDelegate {
        let identifier = UUID().uuidString
        let receiveChatEvent = PublishRelay<Model.Chat.Event>()
        
        init() {
            SendbirdChat.addChannelDelegate(self, identifier: identifier)
        }
        
        func channel(_ channel: BaseChannel, didReceive message: BaseMessage) {
            debugPrint("receive \(message.message)")
            guard let channel = Model.Channel.init(original: channel) else { return }
            guard let chat = Model.Chat.init(original: message) else { return }
            
            self.receiveChatEvent.accept(.receive(channel, chat))
        }
        
        func channel(_ channel: BaseChannel, messageWasDeleted messageId: Int64) {
            debugPrint("deleted \(messageId)")
            guard let channel = Model.Channel.init(original: channel) else { return }
            
            self.receiveChatEvent.accept(.delete(channel, messageId))
        }
    }
}

extension ChatService {
    struct Constant {
        static let messageLimit: UInt = 30
        static let channelLimit: UInt = 30
        static let userLimit: UInt = 100
    }
}
