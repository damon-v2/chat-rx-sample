//
//  GlobalActivityIndicator.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/27.
//

import Foundation
import RxSwift
import RxCocoa
import RxSwiftUtilities

public class GlobalActivityIndicator {
    public static let instance = GlobalActivityIndicator()
    public static var progressRetainCount = 0
    let contentView: UIContentView
    
    public let activityIndicator = ActivityIndicator()

    var disposeBag: DisposeBag! = DisposeBag()
    
    init() {
        self.contentView = UIContentView(frame: UIScreen.main.bounds)
    }
    
    public func showProgress() {
        DispatchQueue.main.async { self.showProgressInWindow() }
    }
    
    public func hideProgress() {
        DispatchQueue.main.async { self.hideProgressInWindow() }
    }
    
    public func removeAllProgress(){
        GlobalActivityIndicator.progressRetainCount = 0
        self.hideProgress()
    }
    
    public func showProgressInWindow(){
        guard GlobalActivityIndicator.progressRetainCount == 0 else {
            GlobalActivityIndicator.progressRetainCount += 1
            return
        }
        
        guard let windowView = UIApplication.shared.windows.first else {
            return
        }
        
        windowView.isUserInteractionEnabled = false
        windowView.addSubview(contentView)
        
        self.contentView.show()
    }
    
    public func hideProgressInWindow(){
        GlobalActivityIndicator.progressRetainCount = max(0, GlobalActivityIndicator.progressRetainCount - 1)
        guard GlobalActivityIndicator.progressRetainCount == 0 else { return }
        guard let windowView = UIApplication.shared.windows.first else { return }
        
        windowView.isUserInteractionEnabled = true
        self.contentView.hide()
        self.contentView.removeFromSuperview()
    }
    
    public var isBusy:Bool {
        get {
            return GlobalActivityIndicator.instance.contentView.superview != nil
        }
    }
}

extension Observable {
    public func bindGlobalActivityIndicator() -> Observable<Element> {
        return self.do(onSubscribed: { GlobalActivityIndicator.instance.showProgress() }, onDispose: { GlobalActivityIndicator.instance.hideProgress() })
    }
}

extension Driver {
    public func bindGlobalActivityIndicator() -> Driver<Element> {
        return self.do(onSubscribed: { GlobalActivityIndicator.instance.showProgress() }, onDispose: { GlobalActivityIndicator.instance.hideProgress() })
            .asOptional().asDriver(onErrorJustReturn: nil).unwrap()
    }
}

public class UIContentView: UIView {
    var animationImgView: UIImageView?
    let indicator = UIActivityIndicatorView()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        self.isUserInteractionEnabled = false
        self.alpha = 0
        indicator.style = UIActivityIndicatorView.Style.large
        self.addSubview(self.indicator)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func show() {
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut)
        
        animator.addAnimations { [weak self] in self?.alpha = 1 }
        animator.startAnimation()
        
        self.indicator.sizeToFit()
        self.indicator.center = self.center
        self.indicator.startAnimating()
    }
    
    public func hide(){
        self.indicator.stopAnimating()
        
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut)
        animator.addAnimations { [weak self] in self?.alpha = 0 }
        animator.addCompletion { [weak self] (_) in self?.removeFromSuperview() }
        animator.startAnimation()
    }
}

protocol LoadingImageView: AnyObject {
    var animationImgView: UIImageView? { get set }
    var animationImages: [UIImage] { get }
    var animationDuration: TimeInterval { get }
}

extension LoadingImageView {
    var animationImages: [UIImage] {
        Array<Int>(1...21).compactMap{ String(format:"loading_%d", $0) }.compactMap(UIImage.init(named:))
    }
    var animationImageSize: CGSize {
        guard let image = UIImage(named: "loading_1")?.size else { return .zero }
        return .init(width: image.width * 2, height: image.height * 2)
    }
    var animationDuration: TimeInterval { 0.8 }
}

extension LoadingImageView {
    public func initializeLoadingView() {
        let images = self.animationImages

        guard let image = images.first else { return }
        
        self.animationImgView = UIImageView(frame: CGRect(x: 0, y: 0,
                                                          width: animationImageSize.width,
                                                          height: animationImageSize.height))
        self.animationImgView?.animationImages = images
        self.animationImgView?.image = image
        self.animationImgView?.animationDuration = self.animationDuration
    }
    
    public func attachAnimateImage(baseView: UIView){
        guard let img = animationImgView else { return }
        
        img.center = CGPoint(x: baseView.frame.size.width / 2,
                             y: baseView.frame.size.height / 2)
        baseView.addSubview(img)
    }
    
    public func removeAnimateImage(){
        self.animationImgView?.removeFromSuperview()
    }
    
    public func startAnimating(){
        self.animationImgView?.startAnimating()
    }
    
    public func stopAnimating(){
        self.animationImgView?.stopAnimating()
    }
}
