//
//  AppTaskQueue.swift
//  BaseProject
//
//  Created suwan.park on 27/11/2019.
//  Copyright © 2019 ipagong.dev. All rights reserved.
//

import Foundation
import SwiftPriorityQueue

/// Task 들을 관리하는 큐의 콘크리트 객체.
/// (우선순위 큐 베이스)
final public class AppTaskQueue: TaskQueueProtocol {
    /// 큐의 싱글톤 인스턴스.
    public static let shared = AppTaskQueue()
    
    /// 우선순위 큐.
    public var queue = PriorityQueue<AppBaseTask>(ascending: true)
    
    /// 현재 진행 중인 Task
    public var runningTask:AppBaseTask?
}
