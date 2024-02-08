//
//  LoginViewController.swift
//  IMChat
//
//  Created by Trey Browder on 1/29/24.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "blackLogo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address"
        
        //add "padding" to the text in the email text field by creating the left field view
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "password"
        field.isSecureTextEntry = true
        
        //add "padding" to the text in the passwprd text field by creating the left field view
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("log in", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    //Facebook login button
    private let faceBookloginButton: FBLoginButton = {
        let button = FBLoginButton()
        
        //can not add email to permissions since this app isnt going to be a legit business
        button.permissions = ["public_profile"]
        
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"

        view.backgroundColor = .white

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        loginButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        faceBookloginButton.delegate = self
        
        //Add subviews here:
        //scroll view first -
        view.addSubview(scrollView)
        //then add views (elements) to the scroll view -
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(faceBookloginButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width)/3,
                                 y: 20,
                                 width: size,
                                 height: size)
        
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom+10,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom+10,
                                   width: scrollView.width - 60,
                                   height: 52)
        
        faceBookloginButton.center = scrollView.center
        faceBookloginButton.frame = CGRect(x: 30,
                                    y: loginButton.bottom+10,
                                    width: scrollView.width - 60,
                                    height: 52)
        
    }
    
    @objc private func loginButtonTapped(){
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty else {
            alertUserEmptyLoginErrorMsg()
            return
        }
        
        spinner.show(in: view)
        
        //Add Firebase Log in functionality here
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResults, error in
            
            guard let strongSelf = self else {
                return
            }
            
            //get rid of spinner once done with firebase auth statements - updating UI needs to be done on main thread
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResults, error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            
            let user = result.user
            print("logged in user: \(user)")
            
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    func alertUserEmptyLoginErrorMsg(){
        let alertMsg = UIAlertController(title: "Invalid Login info",
                                         message: "Please enter your correct account info",
                                         preferredStyle: .alert)
        
        alertMsg.addAction(UIAlertAction(title: "Dissmiss",
                                           style: .cancel,
                                           handler: nil))
        
        present(alertMsg, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        //no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            if let error = error {
                print("user failed to log in with facebook. Error: \(error)")
            }
                return
        }
        
        //add current logged in users email/name to firebase - to do this make a Graph request
        let FBRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                   parameters: ["fields": "email, name"], //email wont work since this isnt an actual business
                                                   tokenString: token,
                                                   version: nil,
                                                   httpMethod: .get)
        
        FBRequest.start(completion: { _, result, error in //_ is a connection - dont know what that is for as i dont need it
            guard let result = result as? [String: Any], error == nil else {
                print("failed to make Facebook graph request")
                return
            }
            //print result to check if name and email come back - email doesn't come back since i dont have email permissions
            //print("\(result)")
            guard let userName = result["name"] as? String else {
                print("failed to get name from FB result ")
                return
            }
            
            //adduser
            DatabaseManager.shared.userExist(with: userName) { exists in
                if !exists {
                    
                    //since i dont own an actual business i created a dummy email to be inserted into database
                    let newIMChatUser: IMChatUser = IMChatUser(firstLastName: userName, emailAddress: "FaceBookTestUsers@test.com")
                    DatabaseManager.shared.insertUser(with: newIMChatUser)
                }
            }
            
            //get the token and set it to a credential variable for authentication through FB
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }
                
                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("FB credential login failed, MFA may be needed - Error: \(error)")
                    }
                    return
                }
                
                print("successfully logged user in")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        })
    }
}
