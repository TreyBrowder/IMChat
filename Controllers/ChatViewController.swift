//
//  ChatViewController.swift
//  IMChat
//
//  Created by Trey Browder on 2/8/24.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit

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

struct Media: MediaItem {
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
    
}

class ChatViewController: MessagesViewController {

    public static let dateFormatter: DateFormatter = {
       let dFormatter = DateFormatter()
        dFormatter.dateStyle = .medium
        dFormatter.timeStyle = .long
        
        //for simulator
        dFormatter.locale = .current
        
        //for actual device
        dFormatter.locale = Locale.init(identifier: "en_US")
        return dFormatter
    }()
    
    public var isNewConversation = false
    private let otherUserEmail: String
    public let conversationId: String?
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
       return  Sender(photoURL: "",
               senderId: safeEmail,
               displayName: "me")
        
        
    }
    
    //custom constructor - override isnt needed
    init(with email: String, id: String?){
        self.otherUserEmail = email
        self.conversationId = id
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
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        setUpInputButton()
        
    }
    
    private func setUpInputButton(){
        let button = InputBarButtonItem()
        //set size at 36 becasue i want a 1 pt buffer from the view in the message input bar set below
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.onTouchUpInside { [weak self]_ in
            self?.presentInputActionSheet()
        }
                       
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        
        let actionSheet = UIAlertController(title: "Add media",
                                            message: "what do you want to add",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            //photo picker action
            self?.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            //video
            self?.presentVideoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Add Photo",
                                            message: "From Camera or Library",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            //photo picker from camera
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: {  [weak self] _ in
            //photo picker from photo library
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    ///method to send video
    private func presentVideoInputActionSheet(){
        let actionSheet = UIAlertController(title: "Add Video",
                                            message: "From Camera or Library",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            //photo picker from camera
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: {  [weak self] _ in
            //photo picker from photo library
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.delegate = self
            picker.allowsEditing = true
            
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func listenFormessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversations(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    print("updating UI")
                    //self?.messagesCollectionView.reloadDataAndKeepOffset()
                    self?.messagesCollectionView.reloadData()
                    
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let err):
                print("failed to get messages: \(err)")
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenFormessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
}

// MARK: - Send photo library/camera
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(),
              let conversationId = conversationId,
              let selfSender = selfSender,
              let name = self.title else {
            return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            
            let fileName = "photo_message_\(messageId).png"
            let resultFileName = fileName.replacingOccurrences(of: " ", with: "-")
            
            //upload image
            
            StorageManager.sharedStorageObj.uploadMessageData(with: imageData, fileName: resultFileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    print("Ready to send message")
                    //upload the photo to the database
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender,
                                           messageId: messageId,
                                           sentDate: Date(),
                                           kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, otherUsersName: name, newMessage: message, completion: { success in
                        
                        if success{
                            print("sent video message")
                        }else {
                            print("failed to send video message")
                        }
                        
                    })
                    
                    
                case .failure(let error):
                    print("failed to upload photo for messaging with erre: \(error)")
                }
            })
            
        }
        else if let videoUrl = info[.mediaURL] as? URL {
            
            let fileName = "video_message_\(messageId).mov"
            let resultFileName = fileName.replacingOccurrences(of: " ", with: "-")
            
            //upload video
            
            StorageManager.sharedStorageObj.uploadVideoMessage(with: videoUrl, fileName: resultFileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    //ready to send message
                    print("uploaded video message url: \(urlString)")
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender,
                                           messageId: messageId,
                                           sentDate: Date(),
                                           kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, otherUsersName: name, newMessage: message, completion: { success in
                        
                        if success{
                            print("sent photo message")
                        }else {
                            print("failed to send photo message")
                        }
                        
                    })
                    
                    
                case .failure(let error):
                    print("failed to upload photo for messaging with error: \(error)")
                }
            })
            
        }
        
        
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    
    ///send button clicked
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        //no empty messages
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
        
        //test to print texts to the console
        print("sending \(text)")
        
        let messages = Message(sender: selfSender,
                               messageId: messageId,
                               sentDate: Date(),
                               kind: .text(text))
        
        //send message integration
        if isNewConversation {
            //create convo in DB
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, otherUsersName: self.title ?? "User", firstMessage: messages) { [weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                }
                else {
                    print("failed to send message")
                }
            }
        }
        else {
            guard let conversationId = conversationId,
            let name = self.title else {
                return
            }
            //append conversation in existing conversation in DB
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, otherUsersName: name, newMessage: messages, completion: { success in
                if success {
                    print("message sent")
                    inputBar.inputTextView.text = ""
                }
                else {
                    print("failed to send message")
                    inputBar.inputTextView.text = ""
                }
            })
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

//message collection view delegate
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil, EMAIL SENDER SHOULD BE CACHED")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
        
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        print("\(indexPath)")
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            
            let vc = PhotoViewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                print("failed to play video")
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
            
        default:
            break
        }
    }
}

