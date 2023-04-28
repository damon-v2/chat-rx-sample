//
//  SplashController.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import UIKit

class SplashController: UIViewController, StoryboardStateSceneType {
    static var storyboardIdentifier: String = "Splash"
}

extension SplashController: StateSceneTransitioning {
    func transition(from: StateSceneType) -> StateScene.Transition {
        switch from {
        default: return .fade(scale: 1.0, duration: 0.3)
        }
    }
}
