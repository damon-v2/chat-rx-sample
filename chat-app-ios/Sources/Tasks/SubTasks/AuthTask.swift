//
//  AuthTask.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import Foundation
import RxSwift

class AuthTask : AppBaseTask {
    private let nextSignal = PublishSubject<String>()
    private let disposeBag = DisposeBag()
    
    override func initialized() {
        nextSignal
            .flatMapLatest{ AuthService.instance.auth(with: $0) }
            .subscribe(onNext: { [weak self] (result) in
                switch result {
                case .success(let user):
                    debugPrint(user.userId)
                    MainContainer.instance?.invoke(state: .main)
                    self?.next()
                case .failure(let error):
                    debugPrint(error.localizedDescription)
                    MainContainer.instance?.invoke(state: .auth)
                    self?.stop()
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    override func execute() {
        guard let userId = AuthService.instance.userId else {
            MainContainer.instance?.invoke(state: .auth)
            self.stop()
            return
        }
        
        self.nextSignal.onNext(userId)
    }
}

