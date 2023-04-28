//
//  AppTaskHandler.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import UIKit

struct AppTaskHandler {
    
    static func didFinish(_ options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        AppTaskQueue.shared.push(.setup, options: options)
        return true
    }
    
    static func initialize(_ options: [UIApplication.LaunchOptionsKey: Any]? = nil) {
        AppTaskQueue.shared.push(.auth, options: options)
        AppTaskQueue.shared.start()
    }
    
    static func sync() {
        AppTaskQueue.shared.push(.auth)
        AppTaskQueue.shared.start()
    }
    
    static func syncAfterError() {
        AppTaskQueue.shared.push(.auth)
        AppTaskQueue.shared.start()
    }
    
    static func destroy() {
        AppTaskQueue.shared.clear()
    }
}
