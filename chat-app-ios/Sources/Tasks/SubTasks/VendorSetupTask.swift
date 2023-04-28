//
//  VenderSetupTask.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import Foundation
import SendbirdChatSDK

class VendorSetupTask: AppBaseTask {
    override func execute() {
        ChatService.instance.setup { [weak self] in self?.next() }
    }
}
