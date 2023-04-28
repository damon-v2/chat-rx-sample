//
//  VCFactory.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/25.
//

import UIKit
import RxSwift

protocol VCFactory: AnyObject {
    static var storyboardIdentifier :String { get }
    static var vcIdentifier: String { get }
    func setupVc()
}

extension VCFactory {
    static var vcIdentifier: String { String(describing: self) }
}

extension VCFactory {
    func setupVc() { }
}

protocol VCBindFactory : VCFactory {
    associatedtype Dependency
    func bindData(_: Dependency)
}


extension VCFactory {
    static func createInstance() -> Self {
        let vcinitialized =
            UIStoryboard(name: self.storyboardIdentifier, bundle: nil)
                .instantiateViewController(withIdentifier: self.vcIdentifier) as! Self
        vcinitialized.setupVc()
        return vcinitialized
    }
    
    static func createSubInstance() -> Self {
        let vcinitialized =
            UIStoryboard(name: self.storyboardIdentifier, bundle: nil)
                .instantiateViewController(withIdentifier: self.vcIdentifier)
        object_setClass(vcinitialized, Self.self)
        (vcinitialized as? Self)?.setupVc()
        return vcinitialized as! Self
    }
}

extension VCBindFactory {
    static func createInstance(_ initial: Self.Dependency) -> Self {
        let vcinitialized = self.createInstance()
        vcinitialized.bindData(initial)
        vcinitialized.setupVc()
        return vcinitialized
    }
    
    static func createSubInstance(_ initial: Self.Dependency) -> Self {
        let vcinitialized = self.createSubInstance()
        vcinitialized.bindData(initial)
        vcinitialized.setupVc()
        return vcinitialized
    }
    
}
