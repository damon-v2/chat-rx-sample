//
//  UIStyleService.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import Foundation
import RxSwift
import RxCocoa

public final class UIStyleService {
    static let instance: UIStyleService = UIStyleService()
    
    private let setupSubject = PublishSubject<UIStyleService.Style>()
    private let disposeBag   = DisposeBag()
    
    private init() {
        setupSubject.startWith(.light)
            .subscribe(onNext: { style in
                guard #available(iOS 13, *) else { return }
                    
                var value : UIUserInterfaceStyle {
                    switch style {
                    case .dark:     return .dark
                    case .light:    return .light
                    case .unknwon:  return .unspecified
                    }
                }
                
                (UIApplication.shared.delegate as? AppDelegate)?.window?.overrideUserInterfaceStyle = value
                
            })
            .disposed(by: disposeBag)
    }
    
    func change(_ style:Style) {
        setupSubject.on(.next(style))
    }
}

extension UIStyleService {
    enum Style {
        case light
        case dark
        case unknwon
    }
}

