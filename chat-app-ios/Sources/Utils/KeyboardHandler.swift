//
//  KeyboardHandler.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/27.
//

import UIKit

protocol KeyboardHandlerProtocol: AnyObject {
    var viewTobeLayout: UIView { get }
}

extension UIViewController: KeyboardHandlerProtocol {
    var viewTobeLayout: UIView { view }
}

final class KeyboardHandler {
    
    unowned var layoutContraints: NSLayoutConstraint
    unowned var delegate: KeyboardHandlerProtocol
    
    init(delegate: KeyboardHandlerProtocol, layoutContraints: NSLayoutConstraint) {
        self.delegate = delegate
        self.layoutContraints = layoutContraints
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(KeyboardHandler.changeKeyboard(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
    }
    
    @objc func changeKeyboard(_ noti: Notification) {
        let keyboardSize  = ((noti.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
        let duration  = ((noti.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue)!
        
        notiHandlerDidChange(UIScreen.main.bounds.height - keyboardSize.origin.y, duration: duration)
    }
    
    func stopKeyboardHandling() {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func notiHandlerDidChange(_ height: CGFloat, duration: Double) {
        delegate.viewTobeLayout.setNeedsUpdateConstraints()
        delegate.viewTobeLayout.updateConstraintsIfNeeded()
        delegate.viewTobeLayout.setNeedsLayout()
        delegate.viewTobeLayout.layoutIfNeeded()
        layoutContraints.constant = height
        delegate.viewTobeLayout.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: UIView.AnimationOptions(),
                       animations: { [weak self] in
            self?.delegate.viewTobeLayout.layoutIfNeeded()
        }, completion: nil)
    }
}

final class KeyboardStateManager {
    
    var loadingFlag = false
    
    @objc func keyboardWillShow() {
        loadingFlag = true
    }
    
    @objc func keyboardDidShow() {
        loadingFlag = false
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardStateManager.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardStateManager.keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
    }
    
    func stopNotification() {
        NotificationCenter.default.removeObserver(self)
    }
}

final class KeyboardFrameListener {
    
    var completion: ((CGFloat) -> Void)?
    
    init(completion: ((CGFloat) -> Void)?) {
        self.completion = completion
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardFrameListener.changeKeyboard(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }
    
    @objc func changeKeyboard(_ noti: Notification) {
        let startSize  = ((noti.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue)!
        
        let endSize  = ((noti.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue)!
        
        completion?(startSize.origin.y - endSize.origin.y)
    }
    
    func stopKeyboardHandling() {
        NotificationCenter.default.removeObserver(self)
    }
}
