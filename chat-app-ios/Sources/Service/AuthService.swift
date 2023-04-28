//
//  AuthService.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import Foundation
import SendbirdChatSDK
import KeychainAccess
import RxSwift

class AuthService {
    static let instance = AuthService()
    
    var userId: String? { Keychain.Service.userId.get() }
    var hasUserId: Bool { userId.isSome }
    
    var currentUser: Model.User?
    
    func auth(with userId: String?) -> Observable<Result<Model.User, Error>> {
        guard let id = userId else { return .error(NSError()) }
        
        return Observable<Result<Model.User, Error>>.create { observer in
            SendbirdChat.connect(userId: id) { result, error in
                guard let user =  Model.User(original: result) else {
                    observer.onNext(.failure(error ?? NSError()))
                    observer.onCompleted()
                    return
                }
                    
                Keychain.Service.userId.set(user.userId)
                AuthService.instance.currentUser = user
                
                observer.onNext(.success(user))
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func logout(target: UIViewController?) -> Observable<Void> {
        guard let target = target else { return .empty()}
        return UIAlertController.rx.show(in: target,
                                  title: "LOGOUT",
                                  message: nil,
                                  buttons: [.cancel("CANCEL"), .default("BYE")])
        .asObservable().filter{ $0 == 1 }.collapseType()
        .flatMapLatest{ AuthService.instance.clear() }
        
    }
        
    func clear() -> Observable<Void> {
        return Observable<Void>.create { observer in
            SendbirdChat.disconnect {
                Keychain.Service.userId.remove()
                AuthService.instance.currentUser = nil
                observer.onNext(())
                observer.onCompleted()
            }
            
            return Disposables.create()
        }
    }
    
    func authPhoto(target: UIViewController?) -> Observable<Void> {
        return MediaAuth.Source.photo.takeStatus().asObservable()
            .flatMapLatest { [weak target] auth -> Observable<Bool> in
                guard let target = target else { return .empty() }
                if auth.isValid == true { return .just(true) }
                
                return UIAlertController.rx.show(in: target,
                                                 title: "PHOTO_AUTH",
                                                 message: nil,
                                                 buttons: [.cancel("CANCEL"), .default("CONFIRM")])
                .asObservable().filter{ $0 == 1 }.collapseType()
                .do(onNext: { URL(string: UIApplication.openSettingsURLString)?.openApplicationURL() })
                .mapTo(false)
        }.filter(identical).collapseType()
    }
    
    func changeNickname(_ nickname: String) -> Observable<Model.User> {
        return Observable.create { observer in
            let params = UserUpdateParams()
            params.nickname = nickname
            SendbirdChat.updateCurrentUserInfo(params: params, completionHandler:  { error in
                if let error = error {
                    observer.onError(error)
                    return
                }
                
                if let user = Model.User(original: SendbirdChat.getCurrentUser()) {
                    AuthService.instance.currentUser = user
                    observer.onNext(user)
                }
                observer.onCompleted()
            })
            
            return Disposables.create()
        }
    }
}
