//
//  AppTaskType.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import Foundation

enum AppTaskType: Int, AppTaskComparable {
    case setup
    case auth
    
    var level: Int { return self.rawValue }
    
    private var taskType: AppBaseTask.Type {
        switch self {
        case .setup: return VendorSetupTask.self
        case .auth: return AuthTask.self
        }
    }
    
    public func task() -> AppBaseTask {
        return self.taskType.init(level: self)
    }
    
}

extension AppTaskQueue {
    func push(_ type: AppTaskType, options:[AnyHashable: Any]? = nil, object: Any? = nil) {
        let task = type.task()
        task.options = options
        task.object = object
        
        self.enQueue(task)
    }
}

