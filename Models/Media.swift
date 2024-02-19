//
//  Media.swift
//  IMChat
//
//  Created by Trey Browder on 2/19/24.
//

import Foundation
import MessageKit

struct Media: MediaItem {
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
    
}
