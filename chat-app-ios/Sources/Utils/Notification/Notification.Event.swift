//
//  Notification.Event.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import Foundation
import UIKit

extension Notification {
    enum Event {
        case uiApplicationDidBecomeActive
        case uiApplicationDidEnterBackground
        case uiApplicationWillResignActive
        case uiKeyboardWillChangeFrame
        case uiApplicationUserDidTakeScreenshot
        case uiWindowDidBecomeKey
    }
}

extension Notification.Event : Notificationable {
    var notiName: String {
        switch self {
        case .uiApplicationDidBecomeActive:
            return UIApplication.didBecomeActiveNotification.rawValue
        case .uiApplicationDidEnterBackground:
            return UIApplication.didEnterBackgroundNotification.rawValue
        case .uiApplicationWillResignActive:
            return UIApplication.willResignActiveNotification.rawValue
        case .uiKeyboardWillChangeFrame:
            return UIResponder.keyboardWillChangeFrameNotification.rawValue
        case .uiApplicationUserDidTakeScreenshot:
            return UIApplication.userDidTakeScreenshotNotification.rawValue
        case .uiWindowDidBecomeKey:
            return UIWindow.didBecomeKeyNotification.rawValue
        }
    }
}
