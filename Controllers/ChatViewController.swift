//
//  ChatViewController.swift
//  IMChat
//
//  Created by Trey Browder on 2/8/24.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    
    public var sender: MessageKit.SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKit.MessageKind
    
}

extension MessageKind {
    var messageKindString: String {
        switch self {
            
        case .text(_):
            return "Text"
        case .attributedText(_):
            return "attribbuted_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    
   public var photoURL: String
   public var senderId: String
   public var displayName: String
    
}

class ChatViewController: MessagesViewController {

    public static let dateFormatter: DateFormatter = {
       let dFormatter = DateFormatter()
        dFormatter.dateStyle = .medium
        dFormatter.timeStyle = .long
        dFormatter.locale = .current
        return dFormatter
    }()
    
    public var isNewConversation = false
    public let otherUserEmail: String
    
    private var messages = [Message]()
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
       return  Sender(photoURL: "",
               senderId: email,
               displayName: "test sender")
        
    }
    
    
    //custom constructor - override isnt needed
    init(with email: String){
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        view.backgroundColor = .red
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    ///send message
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        //no empty messages
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
        
        //test to print texts to the console
        print("sending \(text)")
        
        //send message integration
        if isNewConversation {
            //create convo in DB
            let messages = Message(sender: selfSender,
                                   messageId: messageId,
                                   sentDate: Date(),
                                   kind: .text(text))
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: messages) { success in
                if success {
                    print("message sent")
                }
                else {
                    print("failed to send message")
                }
            }
        }
        else {
            //append conversation in existing conversation in DB
        }
    }
    
    private func createMessageId() -> String? {
        
        //hold the formatted date to use for message ID
        let dateString = Self.dateFormatter.string(from: Date())
        
        //date, otheUSerEmail, senderEmail, randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let mySafeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let newIdentifier = "\(otherUserEmail)_\(mySafeEmail)_\(dateString)"
        print("message id: \(newIdentifier)")
        
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil, EMAIL SENDER SHOULD BE CACHED")
        return Sender(photoURL: "", senderId: "123", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
}
