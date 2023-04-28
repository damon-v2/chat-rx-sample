//
//  SettingController.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import UIKit
import RxSwift
import RxCocoa

class SettingController: BaseController, VCFactory, VCPushStreamable {
    static var storyboardIdentifier: String = "Service"
    
    @IBOutlet weak var nicknameInput: UITextField!
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    var pushCompletion: ((VCPushResult<Bool>) -> Void)!
    
    lazy var viewModel = { ViewModel(target: self) }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.lifeCycle.signalViewWillAppear()
            .bind(to: self.viewModel.input.load)
            .disposed(by: self.disposeBag)
        
        self.nicknameInput.rx.text.asObservable().map{$0 ?? ""}
            .bind(to: self.viewModel.input.nickname)
            .disposed(by: self.disposeBag)
        
        self.changeButton.rx.tap.asObservable()
            .bind(to: self.viewModel.input.changeNickname)
            .disposed(by: self.disposeBag)
        
        self.logoutButton.rx.tap.asObservable()
            .bind(to: self.viewModel.input.logout)
            .disposed(by: self.disposeBag)
        
        self.viewModel.output.original.asObservable()
            .bind(to: self.nicknameInput.rx.text)
            .disposed(by: self.disposeBag)
        
        self.viewModel.output.changeEnabled.asObservable()
            .bind(to: self.changeButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
        
    }
}

extension SettingController {
    class ViewModel: ViewModelType {
        struct Input {
            let load = PublishRelay<Void>()
            let nickname = PublishRelay<String>()
            let changeNickname = PublishRelay<Void>()
            let logout = PublishRelay<Void>()
        }
        
        struct Output {
            let original = PublishRelay<String>()
            let changeEnabled = BehaviorRelay<Bool>(value: false)
        }
        
        let input = Input()
        let output = Output()
        let disposeBag: DisposeBag = DisposeBag()
        
        weak var target: UIViewController?
        
        init(target: UIViewController?) {
            self.target = target
            
            self.input.load.asObservable()
                .map{ AuthService.instance.currentUser?.nickname }
                .unwrap().take(1)
                .bind(to: self.output.original)
                .disposed(by: self.disposeBag)
            
            self.input.nickname.asObservable()
                .withLatestFrom(self.output.original) { (nickname: $0, original: $1) }
                .map{ $0.original != $0.nickname && $0.nickname.count > 3 }
                .bind(to: self.output.changeEnabled)
                .disposed(by: self.disposeBag)
            
            self.input.logout.asObservable()
                .flatMapLatest(weakTo: self) { AuthService.instance.logout(target: $0.target) }
                .subscribe(onNext: { MainContainer.instance.invoke(state: .auth) })
                .disposed(by: self.disposeBag)
            
            self.input.changeNickname.asObservable()
                .withLatestFrom(self.input.nickname)
                .flatMapLatest { nickname in
                    AuthService.instance.changeNickname(nickname)
                }
                .subscribe()
                .disposed(by: self.disposeBag)
        }
    }
}
