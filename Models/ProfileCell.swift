//
//  ProfileCellModel.swift
//  IMChat
//
//  Created by Trey Browder on 2/19/24.
//

import Foundation

enum ProfileCellType {
    case info, logout
}

struct ProfileCell {
    let cellModelType: ProfileCellType
    let title: String
    let handler: (()-> Void)?
}
