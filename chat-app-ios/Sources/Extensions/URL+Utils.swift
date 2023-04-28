//
//  URL+Utils.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/27.
//

import UIKit

extension URL {
    var canOpenApplicationURL:Bool {
        return UIApplication.shared.canOpenURL(self)
    }
    
    func openApplicationURL(_ completionHandler:((Bool) -> Void)? = nil) {
        UIApplication.shared.open(self, options: [:], completionHandler: completionHandler)
    }
}
