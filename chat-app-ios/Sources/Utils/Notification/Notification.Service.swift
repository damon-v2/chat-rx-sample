//
//  Notification.Service.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import Foundation
import UIKit

extension Notification {
    enum Service: String {
        case didFinishedAuth
    }
}

extension Notification.Service : Notificationable {
    var notiName: String { self.rawValue }
}

