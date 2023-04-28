//
//  MainContainer.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import UIKit
import RxSwift
import RxCocoa

class MainContainer: StateContainer<State> {
    static var instance: MainContainer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MainContainer.instance = self
        self.invoke(state: .splash)
    }
    
    override func shouldChange(state: State) -> Bool {
        return true
    }
    
    override func didChange(state: State) {
        //do nothing.
    }
    
    override func invoke(state: State) {
        MainContainer.instance.presentedViewController?.dismissAllPresentedStack()
        if let nv = MainContainer.instance.navigationController {
            nv.popToRootViewController(animated: true) {
                super.invoke(state: state)
            }
        } else {
            super.invoke(state: state)
        }
    }
    
}
    