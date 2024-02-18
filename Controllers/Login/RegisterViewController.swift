//
//  RegisterViewController.swift
//  IMChat
//
//  Created by Trey Browder on 1/29/24.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        
        return imageView
    }()
    
    private let nameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "first and last name"
        
        //add "padding" to the text in the email text field by creating the left field view
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        
        return field
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
        field.backgroundColor = .secondarySystemBackground
        
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
        field.textContentType = .password
        
        //add "padding" to the text in the passwprd text field by creating the left field view
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        
        return field
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Account"
        
        view.backgroundColor = .systemBackground
       
        registerButton.addTarget(self,
                              action: #selector(registerButtonTapped),
                              for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        //Add subviews here:
        //scroll view first -
        view.addSubview(scrollView)
        //then add views (elements) to the scroll view -
        scrollView.addSubview(imageView)
        scrollView.addSubview(nameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(registerButton)

        //enable the user interation with the image and the scroll view
        //in order to tap the picture to change it
        //create a gesture variable then add that to the imageView
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        imageView.addGestureRecognizer(gesture)
        
    }
    
    @objc private func didTapChangeProfilePic(){
        presentPhotoActionSheet()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width)/3,
                                 y: 20,
                                 width: size,
                                 height: size)
        //set corner radis for the imageview after user selects/takes a pic for profile
        imageView.layer.cornerRadius = imageView.width/2.0
        
        nameField.frame = CGRect(x: 30,
                                  y: imageView.bottom+10,
                                  width: scrollView.width - 60,
                                  height: 52)
        emailField.frame = CGRect(x: 30,
                                  y: nameField.bottom+10,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        registerButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom+10,
                                   width: scrollView.width - 60,
                                   height: 52)
    }
    
    @objc private func registerButtonTapped(){
        
        nameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let name = nameField.text, let email = emailField.text, let password = passwordField.text,
              !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            alertUserEmptyLoginErrorMsg()
            return
        }
        
        spinner.show(in: view)
        
        //Add Firebase Log in functionality below
        DatabaseManager.shared.userExist(with: email, completion: { [weak self] exists in
            guard let strongSelf = self else {
                return
            }
            
            //dismiss spinner
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard !exists else {
                //user already extis
                strongSelf.alertUserEmptyLoginErrorMsg(message: "Looks like that email already exist")
                return
            }
            
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { authResult, error in
                guard authResult != nil, error == nil else {
                    print("Error creating user")
                    return
                }
                
                //cache new registered user
                CacheManager.cacheObj.cacheUserNameAndEmail(with: name, email: email)
                
                //instert to the Database
                let iMChatUser = IMChatUser(firstLastName: name,
                                            emailAddress: email)
                DatabaseManager.shared.insertUser(with: iMChatUser, completion: { success in
                    if success {
                        //upload imagae
                        guard let image = strongSelf.imageView.image, let data = image.pngData() else {
                            return
                        }
                        let fileName = iMChatUser.profilePicturFileName
                        StorageManager.sharedStorageObj.uploadProfilePic(with: data, fileName: fileName, completion: { result in
                            switch result {
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                print(downloadUrl)
                            case .failure(let error):
                                print("Storage manager error: \(error)")
                            }
                        })
                    }
                })
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
            
        })
    }
    
    func alertUserEmptyLoginErrorMsg(message: String = "Please fill in all info to create an account"){
        let alertMsg = UIAlertController(title: "Invalid Registration info",
                                         message: message,
                                         preferredStyle: .alert)
        
        alertMsg.addAction(UIAlertAction(title: "Dissmiss",
                                         style: .cancel,
                                         handler: nil))
        
        present(alertMsg, animated: true)
    }
    
}

extension RegisterViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            registerButtonTapped()
        }
        
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //2 options:
    //take pic or select pic
    func presentPhotoActionSheet(){
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How would you like to select a picture?",
                                            preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in     // _ in - the action itself
            self?.presentCamera()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Select Photo",
                                            style: .default,
                                            handler: { [weak self] _ in     //weak self - avoid
            self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        
        present(vc, animated: true)
    }
    
    //gets called when user takes a photo or selects a photo
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImg = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.imageView.image = selectedImg
    }
    
    //gets called when a user cancels the photo selection or when user cancels taking a photo
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
