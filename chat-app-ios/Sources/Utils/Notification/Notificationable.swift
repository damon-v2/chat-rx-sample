//
//  Notificationable.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import Foundation
import RxSwift
import RxCocoa

protocol Notificationable {
    var service:String { get }
    var notiName: String { get }
}

extension Notificationable {
    
    public var service:String { return "" }
    
    public var name: Notification.Name { return Notification.Name(rawValue: self.notiName) }
    
    public func postNoti(_ object:Any? = nil){
        NotificationCenter.default.post(name: self.name,
                                        object: nil,
                                        userInfo: self.postUserInfo(object))
    }
    
    func asObservable() -> Observable<Any?> {
        return NotificationCenter.default.rx.notification(self.name).map{ ($0) }.asObservable()
            .map{ $0.userInfo?[Notification.Constant.userInfo] }
    }
    
    private func postUserInfo(_ object:Any?) -> [String:Any]? {
        guard let value = object else { return nil }
        return [Notification.Constant.userInfo : value]
    }
}

extension Notification {
    struct Constant {
        static let userInfo:String = "userInfo"
    }
}
