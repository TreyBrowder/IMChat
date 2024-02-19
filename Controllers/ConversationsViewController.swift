//
//  ViewController.swift
//  IMChat
//
//  Created by Trey Browder on 1/28/24.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

///Controller to show a list of conversations
final class ConversationsViewController: UIViewController {
    
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    
    private var tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCellView.self,
                       forCellReuseIdentifier: ConversationTableViewCellView.identifier)
        
        return table
    }()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No conversations"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        
        return label
    }()
    
    //notifications for the conversation listener after login
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        setUpTableView()
        startListeningForConversations()
        
    }
    
    private func startListeningForConversations(){
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        print("Conversations loading.....")
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        DatabaseManager.databaseSharedObj.getAllConversations(for: safeEmail, completion: {[weak self] result in
            
            switch result {
            case .success(let conversations):
                print("reading data from DB closure converation models for table")
                guard !conversations.isEmpty else {
                    print("conversations is empty")
                    self?.tableView.isHidden = true
                    self?.noConversationsLabel.isHidden = false
                    return
                }
                print("getting ready to update UI now.....")
                self?.noConversationsLabel.isHidden = true
                self?.tableView.isHidden = false
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    print("updating UI now.....")
                    self?.tableView.reloadData()
                }
                
            case .failure(let err):
                print("FAILED TO GET CONVERSATIONS - ERROR: \(err)")
                self?.tableView.isHidden = true
                self?.noConversationsLabel.isHidden = false
            }
        })
    
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        
        noConversationsLabel.frame = CGRect(x: 10,
                                            y: (view.height - 100)/2,
                                            width: view.width-20,
                                            height: 100)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                print("login Observer failed to load conversations on new account login")
                return
            }
            
            strongSelf.startListeningForConversations()
        })
    }
    
    private func validateAuth() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            //want to set nav.modalPresentationStyle to fullscreen - if not specified this way controller pops
            //up as a card and the user can dismiss it even if they arent logged in
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    private func setUpTableView() {
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    
    @objc private func didTapComposeButton(){
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            let currentConversations = strongSelf.conversations
            
            //open an existing conversation
            if let targetConversation = currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }) {
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                //open a new conversation
                strongSelf.createNewConversation(result: result)
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    ///pushes controller with new conversation state
    private func createNewConversation(result: SearchResult){
        print("LOG: createNewConversation function")
        
        let name = result.name
        let email = DatabaseManager.safeEmail(emailAddress: result.email)
        print("name:  \(name)")
        print("email:  \(email)")
        
        //check in database if conversation with these 2 users exists -
        //if it does use that conversation ID if not - new conversation
        
        DatabaseManager.databaseSharedObj.conversationExists(with: email) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            
            switch result {
            case .success(let conversationId):
                
                let vc = ChatViewController(with: email, id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
                
            case .failure(_):
                
                //isn't an actual error - just means that its a brand new conversation
                print("trully a new conversation ignore this failure")
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}

//conversations screen
extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCellView.identifier,
                                                 for: indexPath) as! ConversationTableViewCellView
        cell.config(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        
        openConversation(model)
    }
    
    func openConversation(_ model: Conversation) {
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id)
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        //handle delete function from editingStyleForRowAt
        //delete row
        //updating backing model - if not app would crash:
        //due to mismatch between model array that drives the table view
        //because it have one aditional entry and rows will be one less
        
        if editingStyle == .delete {
            //begin delete
            
            let converionId = conversations[indexPath.row].id
            tableView.beginUpdates()
            conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            
            DatabaseManager.databaseSharedObj.deleteConversation(conversationId: converionId) { success in
                if !success {
                    print("failed to delete")
                    //error handling - add model and row back and show the error
                }
            }
            
            tableView.endUpdates()
        }
    }
    
}
