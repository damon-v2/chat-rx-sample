//
//  UIViewController.+Utils.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import UIKit

extension UIViewController {
    var isFirstLoaded: Bool {
        return self.isBeingPresented || self.isMovingToParent
    }
}

extension UIViewController {
    func setStatusBarBlack(){
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.default
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func setStatusBarWhite(){
        UIApplication.shared.statusBarStyle = UIStatusBarStyle.lightContent
        setNeedsStatusBarAppearanceUpdate()
    }
}

extension UINavigationController {
    
    func pushViewController(_ viewController: UIViewController, animated: Bool, completion:@escaping (()->())) {
        CATransaction.setCompletionBlock(completion)
        CATransaction.begin()
        self.pushViewController(viewController, animated: animated)
        CATransaction.commit()
    }
    
    @discardableResult
    func popViewController(animated: Bool, completion:@escaping (()->())) -> UIViewController? {
        CATransaction.setCompletionBlock(completion)
        CATransaction.begin()
        let viewController = self.popViewController(animated: animated)
        CATransaction.commit()
        return viewController
    }
    
    @discardableResult
    func popToRootViewController(animated: Bool, completion:@escaping (()->())) -> [UIViewController]? {
        CATransaction.setCompletionBlock(completion)
        CATransaction.begin()
        let viewControllers = self.popToRootViewController(animated: animated)
        CATransaction.commit()
        return viewControllers
    }
}

extension UIViewController {
    
    func dismissAllPresentedStack(_ animated:Bool = true, _ completion: (() -> (Void))? = nil) {
        self.dismissPresentedViewController(animated: animated) { completion?() }
    }
    
    private func dismissPresentedViewController(animated:Bool = true, _ completion: (() -> (Void))? = nil) {
        guard let present = self.presentedViewController else {
            completion?()
            return
        }
        
        present.dismissPresentedViewController(animated: true) { [weak present] in
            DispatchQueue.main.async { present?.dismiss(animated: animated, completion: completion) }
        }
    }
}

extension UIViewController {
    
    var hasNavigationController:Bool {
        guard let _ = self.navigationController else { return false }
        return true
    }
    
    var isVisibleController:Bool {
        if let _ = self.presentedViewController { return false }
        if let nv = self.navigationController, nv.topViewController != self { return false }
        return true
    }
    
    var topPresentedViewController:UIViewController {
        var top = self
        while let newTop = top.presentedViewController { top = newTop }
        return top
    }
    
    var topVisibleController:UIViewController {
        let top = self.topPresentedViewController
        return top.children.last ?? top
    }
    
    static var visibleController:UIViewController? {
        guard let rootVc = UIApplication.shared.keyWindow?.rootViewController else { return nil }
        
        var top = rootVc
        while let newTop = top.presentedViewController { top = newTop }
        
        guard let last = top.children.last else { return top }
        
        return last
    }
    
    var lastChildren:UIViewController? {
        var result = self
        while let last = result.children.last { result = last }
        return result
    }
}

import RxSwift

extension UIViewController {
    
    func dismissAllPresentedStackObservable(_ animated:Bool = true) -> Observable<Void>  {
        return Observable<Void>.create({ [weak self] (observer) -> Disposable in
            guard let self = self else { return Disposables.create() }
            
            self.dismissAllPresentedStack(animated) {
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }
    
    func popToRootViewControllerObservable() -> Observable<Void> {
        guard let _ = self.navigationController else { return .just(()) }
        
        return Observable<Void>.create({ [weak self] (observer) -> Disposable in
            guard let nv = self?.navigationController else { return Disposables.create() }
            
            _ = nv.popToRootViewController(animated: true) {
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }
    
    func popControllerObservable() -> Observable<Void> {
        guard let navigation = (self as? UINavigationController) ?? self.navigationController else { return .just(()) }
        
        return Observable<Void>.create({ [weak navigation] (observer) -> Disposable in
            guard let nv = navigation else { return Disposables.create() }
            
            _ = nv.popViewController(animated: true) {
                observer.onNext(())
                observer.onCompleted()
            }
            return Disposables.create()
        })
    }
}

extension UIViewController {
    func dismissUntilDone(_ animated: Bool) {
        if self.isBeingDismissed || self.isBeingPresented {
            DispatchQueue.main.async { self.dismissUntilDone(animated) }
            return
        }
        
        if self.presentingViewController != nil {
            self.dismiss(animated: animated, completion: nil)
        }
    }
}

extension UIViewController {

    var isModal: Bool {

        let presentingIsModal = presentingViewController != nil
        let presentingIsNavigation = navigationController?.presentingViewController?.presentedViewController == navigationController
        let presentingIsTabBar = tabBarController?.presentingViewController is UITabBarController

        return presentingIsModal || presentingIsNavigation || presentingIsTabBar
    }
}



class InteractivePopRecognizer: NSObject, UIGestureRecognizerDelegate {
    var navigationController: UINavigationController?

    init(controller: UINavigationController?) {
        self.navigationController = controller
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navi = self.navigationController else { return false }
        return navi.viewControllers.count > 1
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
