//
//  RxSwift+Custom.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import Foundation
import RxCocoa
import RxSwift
import RxSwiftExt

protocol Optionable {
    
    associatedtype WrappedType
    
    var isNone: Bool { get }
    var isSome: Bool { get }
    
    func unwrap() -> WrappedType
}

extension Optional : Optionable {
    
    typealias WrappedType = Wrapped
    
    var isNone: Bool {
        return self == nil
    }
    
    var isSome: Bool {
        return self != nil
    }
    
    func unwrap() -> WrappedType {
        return self!
    }
}

extension ObservableType where Element : Optionable {
    func unwrap() -> Observable<Element.WrappedType> {
        return self
            .filter { $0.isSome }
            .map { $0.unwrap() }
    }
    
    func unwrapStopped(_ stopped:(() -> ())? = nil) -> Observable<Element.WrappedType> {
        return self
            .filter {
                guard $0.isNone else { return true }
                stopped?()
                return false
            }
            .map { $0.unwrap() }
    }
}

extension Float {
    static fileprivate func random(WithMax max: Float) -> Float {
        return (Float(arc4random()) / Float(UINT32_MAX) * max)
    }
}

extension ObservableType where Element: Optionable {
    func mapSwitchChanneled<T>(transform: @escaping (Element.WrappedType) throws -> Observable<T>) -> Observable<T> {
        return self
            .mapSwitch(transform: { (option) -> Observable<T> in
                guard option.isSome else { return Observable.empty() }
                
                return try transform(option.unwrap())
            })
    }
}

extension ObservableType {
    
    func mapSwitch<T>(transform: @escaping (Self.Element) throws -> Observable<T>) -> Observable<T> {
        return self
            .map(transform)
            .switchLatest()
    }
    
    public func mapToWeak<R>(_ value: R) -> Observable<R?> where R : NSObject {
        return map { [weak value] _ in value }
    }
    
    func randomErrorFilter(percent: Float, error: Error) -> Observable<Element> {
        return self.map {
            if Float.random(WithMax: 1) < percent {
                throw error
            } else {
                return $0
            }
        }
    }
}

extension Observable {
    func asOptional() -> Observable<Element?> {
        return self.map { value -> Element? in return value }
    }
    
    func checkAndDistinct<V: Equatable>(withEvaluation evaluation: @escaping (() -> V)) -> RxSwift.Observable<V> {
        let start = Observable<V>.create { observer -> Disposable in
            observer.onNext(evaluation())
            observer.onCompleted()
            return Disposables.create()
        }
        let second = self.map{ _ in evaluation() }
        return Observable<V>.concat([start, second]).distinctUntilChanged()
    }
    
    func collapseType() -> Observable<Void> {
        return self.map { _ in }
    }
}

//MARK: Driver Extension
extension Driver {
    public func take(_ count: Int) -> Driver<Element> {
        return self.asObservable().take(count).asDriver(onErrorRecover: { _ in fatalError() })
    }
    
    func collapseType() -> Driver<Void> {
        return self.map { _ in }.asDriver(onErrorRecover: { _ in fatalError() })
    }
    
    public func mapTo<R>(_ value: R) -> Driver<R> {
        return self.asObservable().mapTo(value).asDriver(onErrorRecover: { _ in fatalError() })
    }
    
    func asOptional() -> Driver<Element?> {
        return self.asObservable().map { value -> Element? in return value }.asDriver(onErrorRecover: { _ in fatalError() })
    }
    
    func takeUntil<O: ObservableType>(_ other: O) -> Driver<Element> {
        return self.asObservable().takeUntil(other).asDriver(onErrorRecover: { _ in fatalError() })
    }
    
    func throttle(_ dueTime: RxTimeInterval, latest: Bool = true, scheduler: SchedulerType) -> Driver<Element> {
        return self.asObservable().throttle(dueTime, latest: latest, scheduler: scheduler).asDriver(onErrorRecover: { _ in fatalError() })
    }
    
    func mapSwitch<T>(transform: @escaping (SharedSequence.Element) -> Driver<T>) -> Driver<T> {
        return self.asObservable().map(transform).switchLatest().asDriver(onErrorRecover: { _ in fatalError() })
    }
    
    func mapSwitch<T>(transform: @escaping (SharedSequence.Element) throws -> Observable<T>) -> Observable<T> {
        return self.asObservable().mapSwitch(transform: transform)
    }
}

extension Driver where Element : Optionable {
    func unwrap() -> Driver<Element.WrappedType> {
        return self.asObservable().unwrap().asDriver(onErrorRecover: { _ in fatalError() })
    }
}

extension ObservableType where Element : SharedSequenceConvertibleType, Element.SharingStrategy == DriverSharingStrategy {
    
    public func switchLatestAsDriver() -> Driver<Element.Element> {
        return self.switchLatest()
            .asDriver { (_) -> SharedSequence<DriverSharingStrategy, Self.Element.Element> in
                fatalError()
        }
    }
}

extension Observable {
    func catchErrorJustComplete(_ closure:(()->())? = nil) -> Observable<Element> {
        return self.catchError { _ in
            closure?()
            return Observable.empty()
        }
    }
    
    func asDriverJustComplete() -> Driver<Element> {
        return self.asDriver { _ in Driver.empty() }
    }
}

import UIKit
extension Reactive where Base: UIResponder {
    public var onFocus:Binder<Bool> {
        return Binder<Bool>(self.base) { (base, value) in
            if value == true {
                base.becomeFirstResponder()
                return
            }
            
            if base.isFirstResponder {
                base.resignFirstResponder()
                return
            }
        }
    }
}

extension ObservableType {
    func filter(_ predicate: @escaping (Element) -> Bool, stopped: @escaping () -> Void) -> Observable<Self.Element> {
        self.filter{ value in
            let result = predicate(value)
            if result == false { stopped() }
            return result
        }
    }
    
    func filter<A: AnyObject>(weak obj: A?, selector: @escaping (A, Self.Element) throws -> Bool) -> Observable<Self.Element> {
        return filter{ [weak obj] value -> Bool in try obj.map { try selector($0, value) } ?? false }
    }
    
    func filter<A: AnyObject>(weakTo obj: A?, selector: @escaping (A) throws -> Bool) -> Observable<Self.Element> {
          return filter{ [weak obj] value -> Bool in try obj.map { try selector($0) } ?? false }
      }
    
    func flatMap<A: AnyObject, O: ObservableType>(weak obj: A?, selector: @escaping (A, Self.Element) throws -> O) -> Observable<O.Element> {
        return flatMap { [weak obj] value -> Observable<O.Element> in
            try obj.map { try selector($0, value).asObservable() } ?? .empty()
        }
    }
    
    func flatMapFirst<A: AnyObject, O: ObservableType>(weak obj: A?, selector: @escaping (A, Self.Element) throws -> O) -> Observable<O.Element> {
        return flatMapFirst { [weak obj] value -> Observable<O.Element> in
            try obj.map { try selector($0, value).asObservable() } ?? .empty()
        }
    }
    
    func flatMapLatest<A: AnyObject, O: ObservableType>(weak obj: A?, selector: @escaping (A, Self.Element) throws -> O) -> Observable<O.Element> {
        return flatMapLatest { [weak obj] value -> Observable<O.Element> in
            try obj.map { try selector($0, value).asObservable() } ?? .empty()
        }
    }
    
    func flatMap<A: AnyObject, O: ObservableType>(weakTo obj: A?, selector: @escaping (A) throws -> O) -> Observable<O.Element> {
        return flatMap { [weak obj] _ -> Observable<O.Element> in
            try obj.map { try selector($0).asObservable() } ?? .empty()
        }
    }
    
    func flatMapFirst<A: AnyObject, O: ObservableType>(weakTo obj: A?, selector: @escaping (A) throws -> O) -> Observable<O.Element> {
        return flatMapFirst { [weak obj] _ -> Observable<O.Element> in
            try obj.map { try selector($0).asObservable() } ?? .empty()
        }
    }
    
    func flatMapLatest<A: AnyObject, O: ObservableType>(weakTo obj: A?, selector: @escaping (A) throws -> O) -> Observable<O.Element> {
        return flatMapLatest { [weak obj] _ -> Observable<O.Element> in
            try obj.map { try selector($0).asObservable() } ?? .empty()
        }
    }
    
    public func subscribe<A: AnyObject>(weakTo obj: A?, _ onNext: @escaping (A) -> Void) -> Disposable {
        return self.subscribe(onNext: { (_) in obj.map { onNext($0) } })
    }
    
    func `do`<A: AnyObject>(weak obj: A?, _ onNext: @escaping (A, Self.Element) throws -> Void) -> Observable<Self.Element> {
        return self.do(onNext: { [weak obj] value in
            try obj.map { try onNext($0, value) }
        })
    }
    
    func `do`<A: AnyObject>(weakTo obj: A?, _ onNext: @escaping (A) throws -> Void) -> Observable<Self.Element> {
        return self.do(onNext: { [weak obj] value in
            try obj.map { try onNext($0) }
        })
    }
    
    func map<A: AnyObject, R>(weak obj: A?, transform: @escaping (A, Self.Element) throws -> R) -> Observable<R> {
        return self.map { [weak obj] value in
            try obj.map { try transform($0, value) }
            }
            .unwrap()
    }
    
    func map<A: AnyObject, R>(weakTo obj: A?, transform: @escaping (A) throws -> R) -> Observable<R> {
        return self.map { [weak obj] value in
            try obj.map { try transform($0) }
            }
            .unwrap()
    }
    
    func subscribe<A: AnyObject>(weak obj: A, _ onNext: @escaping (A, Self.Element) -> Void) -> Disposable {
        return self.subscribe(onNext: weakify(obj, method: onNext))
    }
    
    private func weakify<A: AnyObject, B>(_ obj: A, method: ((A, B) -> Void)?) -> ((B) -> Void) {
        return { [weak obj] value in
            guard let obj = obj else { return }
            method?(obj, value)
        }
    }
}

extension ObservableType {
    func viewAnimationFirst<A: AnyObject>(weak obj: A?, duration: TimeInterval = 0.15, animations: @escaping ((A, Self.Element) -> Void)) -> Observable<Self.Element> {
        return flatMapFirst { [weak obj] value -> Observable<Self.Element> in
            return Observable<Self.Element>.create { [weak obj] (observer) -> Disposable in
                guard let obj = obj else { return Disposables.create() }
                
                let animator = UIViewPropertyAnimator.init(duration: duration, curve: .linear)
                
                animator.addAnimations { animations(obj, value) }
                
                animator.addCompletion { (position) in
                    if position == .end {
                        observer.onNext(value)
                        observer.onCompleted()
                    }
                }
                
                animator.startAnimation()
                
                return Disposables.create()
            }}
    }
    
    func viewAnimationLatest<A: AnyObject>(weak obj: A?, duration: TimeInterval = 0.15, animations: @escaping ((A, Self.Element) -> Void)) -> Observable<Self.Element> {
        return flatMapLatest { [weak obj] value -> Observable<Self.Element> in
            return Observable<Self.Element>.create { [weak obj] (observer) -> Disposable in
                guard let obj = obj else { return Disposables.create() }
                
                let animator = UIViewPropertyAnimator.init(duration: duration, curve: .linear)
                
                animator.addAnimations { animations(obj, value) }
                
                animator.addCompletion { (position) in
                    if position == .end {
                        observer.onNext(value)
                        observer.onCompleted()
                    }
                }
                
                animator.startAnimation()
                
                return Disposables.create()
            }}
    }
}

extension ObservableType {
  func retry(maxAttempts: Int, delay: RxTimeInterval) -> Observable<Element> {
    return self.retryWhen { errors in
      return errors.enumerated().flatMap { (index, error) -> Observable<Int64> in
        if index <= maxAttempts {
          return Observable<Int64>.timer(delay, scheduler: MainScheduler.instance)
        } else {
          return Observable.error(error)
        }
      }
    }
  }
}

func identical<T>(_ val: T) -> T {
    return val
}
