//
//  ViewController.swift
//  IMChat
//
//  Created by Trey Browder on 1/28/24.
//

import UIKit

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let isLoggedIn = UserDefaults.standard.bool(forKey: "logged_in")
        
        if !isLoggedIn {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            //want to set nav.modalPresentationStyle to fullscreen - if not specified this way controller pops
            //up as a card and the user can dismiss it even if they arent logged in
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }

}

