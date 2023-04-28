//
//  AuthController.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import UIKit
import RxSwift
import RxCocoa
import Toast_Swift

class AuthController: BaseController, StoryboardStateSceneType {
    static var storyboardIdentifier: String = "Service"
    
    @IBOutlet weak var userIdField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    
    let viewModel = ViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userIdField.rx.text.asObservable()
            .map{ $0 ?? "" }
            .bind(to: self.viewModel.input.value)
            .disposed(by: self.disposeBag)
        
        loginButton.rx.tap.asObservable()
            .bind(to: self.viewModel.input.auth)
            .disposed(by: self.disposeBag)
        
        viewModel.output.enabled.asObservable()
            .bind(to: self.loginButton.rx.isEnabled)
            .disposed(by: self.disposeBag)
        
        viewModel.output.result.asObservable()
            .subscribe(onNext: { [weak self] result in
                switch result {
                case .success:
                    MainContainer.instance.invoke(state: .main)
                case .failure(let error):
                    self?.view.makeToast(error.localizedDescription)
                    break
                }
            }).disposed(by: self.disposeBag)
             
    }
}

extension AuthController {
    class ViewModel: ViewModelType {
        struct Input {
            let value = PublishRelay<String>()
            let auth = PublishRelay<Void>()
        }
        
        struct Output {
            let enabled = BehaviorRelay<Bool>(value: false)
            let result = PublishRelay<Result<Model.User, Error>>()
        }
        
        let input = Input()
        let output = Output()
        let disposeBag: DisposeBag = DisposeBag()
        
        init() {
            input.value.asObservable()
                .map{ $0.count > 0 }
                .bind(to: output.enabled)
                .disposed(by: self.disposeBag)
            
            input.auth
                .throttle(.seconds(3), scheduler: MainScheduler.instance)
                .withLatestFrom(self.output.enabled).filter{$0}
                .withLatestFrom(self.input.value)
                .flatMapLatest{ AuthService.instance.auth(with: $0) }
                .bind(to: self.output.result)
                .disposed(by: self.disposeBag)
        }
    }
}

extension AuthController: StateSceneTransitioning {
    func transition(from: StateSceneType) -> StateScene.Transition {
        .fade(scale: 1.0, duration: 0.3)
    }
}
