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
        UserDefaults.standard.setValue(nil, forKey: "name")
        UserDefaults.standard.setValue(nil, forKey: "email")
    }
    
    func cacheUserName(with name: String) {
        UserDefaults.standard.set(name, forKey: "name")
    }
    
    func cacheUserEmail(with email: String) {
        UserDefaults.standard.set(email, forKey: "email")
    }
    
    func cacheUserNameAndEmail(with name: String, email: String) {
        UserDefaults.standard.set(name, forKey: "name")
        UserDefaults.standard.set(email, forKey: "email")
    }
}
