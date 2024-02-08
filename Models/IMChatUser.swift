//
//  IMChatUser.swift
//  IMChat
//
//  Created by Trey Browder on 2/8/24.
//

import Foundation

struct IMChatUser {
    let firstLastName: String
    let emailAddress: String
    var profilePicturFileName: String {
        //images/${user_email}.png
        
        return "\(safeEmail)_profile_picture.png"
    }
    //  birthDate: ?
    
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}
