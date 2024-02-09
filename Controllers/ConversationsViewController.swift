//
//  ViewController.swift
//  IMChat
//
//  Created by Trey Browder on 1/28/24.
//

//
//  ViewController.swift
//  IMChat
//
//  Created by Trey Browder on 1/28/24.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class ConversationsViewController: UIViewController {
    
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        setUpTableView()
        fetchConversations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
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
    
    private func fetchConversations(){
        tableView.isHidden = false
    }
    
    @objc private func didTapComposeButton(){
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            //print("\(result)")
            self?.createNewConversation(result: result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    ///pushes controller with new conversation state
    private func createNewConversation(result: [String: String]){
        //unwrap the result to get name and email
        guard let name = result["name"], let email = result["email"] else {
            //log func name for any possible error handling
            print("Function name: createNewConversation(result: [String: String])")
            print("failed to get name and email from the result")
            return
        }
        let vc = ChatViewController(with: email)
        vc.isNewConversation = true
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Hello World"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let vc = ChatViewController(with: "fakeEmail@gmail.com")
        vc.title = "Jenny Smith"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

