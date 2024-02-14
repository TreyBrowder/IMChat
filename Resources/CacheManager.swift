//
//  CacheManager.swift
//  IMChat
//
//  Created by Trey Browder on 2/14/24.

import Foundation
import SDWebImage

class CacheManager {
    
    static let cacheObj = CacheManager()
    
    // Clear all values from the cache
    func removeAll() {
        SDImageCache.shared.clear(with: .all)
        UserDefaults.standard.removeObject(forKey: "name")
        UserDefaults.standard.removeObject(forKey: "email")
    }
}
