//
//  RxImagePicker.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/27.
//

import Foundation
import RxSwift
import RxCocoa

struct ImagePicker { }

extension ImagePicker {
    static func getStream(_ presenter: UIViewController?) -> Observable<UIImage?> {
        guard let target = presenter else { return .just(nil) }
        
        return UIImagePickerController.rx.create(target) { picker in
            #if targetEnvironment(simulator)
            picker.sourceType = .photoLibrary
            #else
            picker.sourceType = .photoLibrary
            #endif
            picker.allowsEditing = true
        }
        .mapSwitch { $0.rx.didFinishPick }.take(1)
        .map { $0[UIImagePickerController.InfoKey.editedImage.rawValue] as? UIImage }
        .unwrap()
        .delay(.milliseconds(300), scheduler: MainScheduler.instance)
        .share(replay: 1)
    }
}

open class RxImagePickerDelegateProxy: RxNavigationControllerDelegateProxy, UIImagePickerControllerDelegate {
    fileprivate static var didRegist:Bool = false {
        willSet {
            guard didRegist == false, newValue == true else { return }
            RxImagePickerDelegateProxy.register { RxImagePickerDelegateProxy(imagePicker: $0) }
        }
    }
    
    public init(imagePicker: UIImagePickerController) {
        super.init(navigationController: imagePicker)
    }
}

extension Reactive where Base: UIImagePickerController {
    static func create(_ parent: UIViewController?, animated: Bool = true, configure: ((UIImagePickerController) throws -> ())? = nil) -> Observable<UIImagePickerController> {
        RxImagePickerDelegateProxy.didRegist = true
        
        return Observable.create { [weak parent] observer in
            let picker = UIImagePickerController()
            
            do { try configure?(picker) }
            catch let error {
                observer.on(.error(error))
                return Disposables.create()
            }
            
            guard let parent = parent else {
                observer.on(.completed)
                return Disposables.create()
            }
            
            parent.present(picker, animated: animated, completion: nil)
            observer.on(.next(picker))
            
            let dismiss = picker.rx.didCancel.subscribe(onNext: { [weak picker] _ in
                picker?.dismissUntilDone(animated)
            })
            
            let disposed = Disposables.create { [weak picker] in
                picker?.dismissUntilDone(animated)
            }
            
            return Disposables.create(dismiss, disposed)
        }
    }
}


extension Reactive where Base: UIImagePickerController {
    
    public var didFinishPick: Observable<[String : AnyObject]> {
        return delegate
            .methodInvoked(#selector(UIImagePickerControllerDelegate.imagePickerController(_:didFinishPickingMediaWithInfo:)))
            .map({ (a) in
                return try castOrThrow(Dictionary<String, AnyObject>.self, a[1])
            })
    }
    
    public var didCancel: Observable<()> {
        return delegate
            .methodInvoked(#selector(UIImagePickerControllerDelegate.imagePickerControllerDidCancel(_:)))
            .map {_ in () }
    }
    
}

fileprivate func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T {
    guard let returnValue = object as? T else {
        throw RxCocoaError.castingError(object: object, targetType: resultType)
    }
    return returnValue
}
