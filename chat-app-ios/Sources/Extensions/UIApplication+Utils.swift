//
//  UIApplication.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/24.
//

import UIKit

extension UIApplication {
    func findWindow() -> UIWindow? {
        if #available(iOS 13, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
