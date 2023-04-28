//
//  VCStreamable.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/25.
//

import UIKit
import RxSwift
import RxCocoa

protocol VCPushStreamable {
    associatedtype Element
    var pushCompletion: ((VCPushResult<Element>) -> Void)! { get set }
}

protocol VCPresentStreamable {
    associatedtype Element
    var presentCompletion: ((Element) -> Void)! { get set }
}

enum VCPushResult<Element> {
    case next(Element)
    case complete(Element)
    
    var value: Element {
        switch self {
            case .next(let value): return value
            case .complete(let value): return value
        }
    }
}

extension VCPresentStreamable where Self: UIViewController {
    func getStream(presenter: UIViewController,
                   style: UIModalPresentationStyle? = nil,
                   animated:Bool? = true) -> Observable<Element> {
        return Observable<Element>.create { [weak self, weak presenter] observer -> Disposable in
            guard var self = self, let presenter = presenter else { return Disposables.create() }
            
            self.presentCompletion = { [weak self] value in
                self?.dismiss(animated: animated!)
                observer.onNext(value)
                observer.onCompleted()
            }
            
            style.map { self.modalPresentationStyle = $0 }
            presenter.present(self, animated: animated!, completion: nil)
            
            return Disposables.create { [weak self] in
                guard let `self` = self else { return }
                self.dismiss(animated: animated!, completion: nil)
            }
        }
        .delay(.milliseconds(300), scheduler: MainScheduler.instance)
        .take(1)
    }
}

extension VCPushStreamable where Self: UIViewController {
    
    @discardableResult
    func getNavigationStream(presenter: UIViewController,
                             type:UINavigationController.Type = UINavigationController.self,
                             style: UIModalPresentationStyle? = .fullScreen,
                             hiddenNavigation: Bool = false,
                             animated:Bool? = true) -> Observable<Element> {
        return Observable<Element>.create { [weak self] observer -> Disposable in
            guard var self = self else { return Disposables.create() }
            
            self.pushCompletion = { [weak self] result in
                switch result {
                    case .next(let value):
                        observer.onNext(value)
                    case .complete(let value):
                        observer.onNext(value)
                        observer.onCompleted()
                }
                
                if self?.navigationController == .none { observer.onCompleted() }
            }
            
            let nv = type.init(rootViewController: self)
            
            style.map { [weak nv] in
                nv?.modalPresentationStyle = $0
                nv?.setNavigationBarHidden(hiddenNavigation, animated: false)
            }
            
            presenter.present(nv, animated: animated!, completion: nil)
            
            return Disposables.create { [weak nv] in nv?.dismissUntilDone(true) }
            
        }.takeUntil(self.rx.deallocated)
        .delay(.milliseconds(300), scheduler: MainScheduler.instance)
        .take(1)
    }
    
    @discardableResult
    func pushStream(nv: UINavigationController?, animated:Bool? = true) -> Observable<Element> {
        return Observable<Element>.create { [weak self, weak nv] observer -> Disposable in
            guard var `self` = self, let nv = nv else { return Disposables.create() }
            
            self.pushCompletion = { [weak self] result in
                switch result {
                    case .next(let value):
                        observer.onNext(value)
                    case .complete(let value):
                        observer.onNext(value)
                        observer.onCompleted()
                }
                if self?.navigationController == .none { observer.onCompleted() }
            }
            
            nv.pushViewController(self, animated: animated!)
            
            return Disposables.create { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
        }.takeUntil(self.rx.deallocated)
        .delay(.milliseconds(300), scheduler: MainScheduler.instance)
        .take(1)
    }
}
