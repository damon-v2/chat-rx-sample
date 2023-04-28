//
//  BaseController.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import UIKit
import RxSwift

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    var input: Input { get }
    var output: Output { get }
}

class BaseController: UIViewController {
    
    var disposeBag: DisposeBag! = DisposeBag()
    
    var willRemoveBag: Bool = false
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.navigationController?.isBeingDismissed == true || self.isMovingFromParent == true {
            self.willRemoveBag = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.willRemoveBag = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        guard self.willRemoveBag == true else { return }
        self.disposeBag = nil
    }
}

