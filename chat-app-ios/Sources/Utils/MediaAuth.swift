//
//  MediaAuth.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/27.
//

import Foundation
import AVFoundation
import Photos

class MediaAuth : NSObject { }

extension MediaAuth {
    enum Source {
        case photo
        case video
    }
    
    enum Result {
        case authorized
        case denied
        case notDetermined
        case restricted
        case limited
        case unknown
        
        var isValid: Bool {
            self == .authorized || self == .limited
        }
    }
}

extension MediaAuth.Source {
 
    var status:MediaAuth.Result {
        switch self {
        case .photo:
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized:       return .authorized
            case .denied:           return .denied
            case .notDetermined:    return .notDetermined
            case .restricted:       return .restricted
            case .limited:          return .limited
            @unknown default:       return .unknown
            }
            
        case .video:
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:       return .authorized
            case .denied:           return .denied
            case .notDetermined:    return .notDetermined
            case .restricted:       return .restricted
            @unknown default:       return .unknown
            }
        }
    }
    
    func request(_ completion:@escaping (Bool) -> ()) {
        switch self {
        case .photo: PHPhotoLibrary.requestAuthorization { completion(.authorized == $0)  }
        case .video: AVCaptureDevice.requestAccess(for: .video) { completion($0) }
        }
    }
}

import RxSwift
import RxCocoa

extension MediaAuth.Source {
    
    func onStatus() -> Observable<MediaAuth.Result> {
        return Observable.just(self.status)
    }
    
    func onValidate() -> Observable<Bool> {
        return self.onStatus().map { $0 == .authorized }
    }
    
    func takeStatus() -> Observable<MediaAuth.Result> {
        return Observable<MediaAuth.Result>.create { (observer) -> Disposable in
            switch self.status {
            case .notDetermined: self.request { observer.onNext($0 ? .authorized : .denied) }
            case .authorized:    observer.onNext(.authorized)
            case .denied:        observer.onNext(.denied)
            case .restricted:    observer.onNext(.restricted)
            case .limited:       observer.onNext(.limited)
            case .unknown:       observer.onNext(.unknown)
            }
            
            return Disposables.create()
        }
        
    }
}
