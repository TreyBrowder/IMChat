//
//  StorageManager.swift
//  IMChat
//
//  Created by Trey Browder on 2/8/24.
//

import Foundation
import FirebaseStorage


///Allows you to get fetch, and upload files to firebase storage
final class StorageManager {
    
    ///shared instance of the storage manager class
    static let sharedStorageObj = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    private init(){}
    
    /*
     formatt for the image path in the firebase storage
     /images/${user_email}.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    ///Upload picture to firebase sotrage and returns completion with URL string to download
    public func uploadProfilePic(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("images/\(fileName)").downloadURL(completion: { url , error in
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
    
    ///upload image to be sent in a message
    public func uploadMessageData(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url , error in
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
    
    ///upload video to be sent in a message
    public func uploadVideoMessage(with fileUrl: URL, fileName: String, completion: @escaping UploadPictureCompletion){
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload video message to firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            print("successfully uploaded video message to firebase Storage")
            print("Attempting to get download URL")
            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url , error in
                guard let url = url else {
                    print("Failed to get video message download URL")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("SUCCESS - video download URL String: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    ///Download image URL for a given path
    /// Parameters
    /// - `Path`:              Target path in firebase storage  to be downloaded
    /// - `completion`:   Async closure to return with result
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadURL))
                return
            }
            completion(.success(url))
        })
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadURL
    }
}
