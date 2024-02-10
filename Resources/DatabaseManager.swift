//
//  DatabaseManager.swift
//  IMChat
//
//  Created by Trey Browder on 2/5/24.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

// MARK: - Account Management

extension DatabaseManager {
    
    public func userExist(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    ///get all users method sends back a result holding
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error >) -> Void){
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
    ///Insert new user into database
    public func insertUser(with user: IMChatUser, completion: @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "full_name": user.firstLastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("failed to write to Database")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    //append to user diction
                    let newElement = [
                        [
                            "name": user.firstLastName,
                            "email": user.safeEmail
                        ]
                    ]
                    usersCollection.append(contentsOf: newElement)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
                else {
                    //create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstLastName,
                            "email": user.safeEmail
                        ]
                    ]
    
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            })
            completion(true)
        })
    }
}


// MARK: - Send messages /conversations

extension DatabaseManager {
    
    ///create a new conversation with user email and first message sent
    public func createNewConversation(with otherUserEmail: String, otherUsersName: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapShot in
            guard var userNode = snapShot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            //constant to hold ID for root node conversation ID
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            // data needed for a new conversation - this will be attached as a dictionary to sender node in DB
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "other_user_name": otherUsersName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            // data needed for a new conversation - this will be attached as a dictionary to receiver node in DB
            let recipientNewConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "other_user_name": "self",
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            //logic to update recipient conversation
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapShot in
                if var conversations = snapShot.value as? [[String: Any]] {
                    //append
                    conversations.append(recipientNewConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else {
                    //create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipientNewConversationData])
                }
            })
            
            //logic to update current user conversation
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user
                // so append to existing node
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { [weak self ]error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(otherUsersName: otherUsersName,
                                                     conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            }
            else {
                //conversation array doesnt exist - create it
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode, withCompletionBlock: { [ weak self ] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(otherUsersName: otherUsersName,
                                                     conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                })
            }
        })
    }
    
    
    private func finishCreatingConversation(otherUsersName: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUrserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUrserEmail,
            "is_read": false,
            "other_user_name": otherUsersName
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("adding conversion: \(conversationID) to Firebase")
        
        database.child("\(conversationID)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    ///Fetches and returs all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void){
        database.child("\(email)/conversations").observe(.value, with: { snapShot in
            print("looking at conversations values")
            guard let value = snapShot.value as? [[String: Any]] else {
                print("failed to get conversation values")
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            print("attempting to read from DB...")
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let name = dictionary["other_user_name"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let sentDate = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool
                else {
                    print("failed to read from DB")
                    return nil
                }

                print("Starting to return conversations")
                let lastestMessagesObj = LatestMessage(date: sentDate,
                                                       text: message,
                                                       isRead: isRead)
                return Conversation(id: conversationId, 
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: lastestMessagesObj)
            })
            
            completion(.success(conversations))
        })
    }
    
    /// Gets all messages for a given conversation
    public func getAllMessagesForConversations(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: { snapShot in
            print("looking at message values")
            guard let value = snapShot.value as? [[String: Any]] else {
                print("failed to get message values")
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            print("attempting to read messages from DB...")
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["other_user_name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                let content = dictionary["content"] as? String,
                let senderEmail = dictionary["sender_email"] as? String,
                let dateString = dictionary["date"] as? String,
                let date = ChatViewController.dateFormatter.date(from: dateString),
                let type = dictionary["type"] as? String else {
                    print("ERROR: failed to read messages in DataBase...returning nil")
                    return nil
                }
                print("SUCCESS: read messages from DB...return data")
                
                let sender = Sender(photoURL: "",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: .text(content))
            
            })
            completion(.success(messages))
        })
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
    }
}
