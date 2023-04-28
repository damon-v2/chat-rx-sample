//
//  Collection+Safe.swift
//  chat-app-ios
//
//  Created by Damon Park on 2023/04/26.
//

import Foundation

extension Collection {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
