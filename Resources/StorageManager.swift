//
//  StorageManager.swift
//  IMChat
//
//  Created by Trey Browder on 2/8/24.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let sharedStorageObj = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    
    /*
     /images/${user_email}.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    ///Upload picture to firebase sotrage and returns completion with URL string to download
    public func uploadProfilePic(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL(completion: { url , error in
                guard let url = url else {
                    print("Failed to get download URL")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("downloaded URL String: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadURL
    }
}
