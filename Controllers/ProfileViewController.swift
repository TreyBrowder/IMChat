//
//  ProfileViewController.swift
//  IMChat
//
//  Created by Trey Browder on 1/29/24.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit

enum ProfileCellModelType {
    case info, logout
}

struct ProfileCellModel {
    let cellModelType: ProfileCellModelType
    let title: String
    let handler: (()-> Void)?
}

class ProfileViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    //need multiple cells
    var data = [ProfileCellModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        data.append(ProfileCellModel(cellModelType: .info,
                                     title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")",
                                     handler: nil))
        data.append(ProfileCellModel(cellModelType: .info,
                                     title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")",
                                     handler: nil))
        data.append(ProfileCellModel(cellModelType: .logout, title: "Log Out", handler: {[ weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive,
                                                handler: { [weak self] _ in
                
                guard let strongSelf = self else {
                    return
                }
                
                //clear Cache from previous user
                CacheManager.cacheObj.removeAll()
                
                //Log out facebook
                FBSDKLoginKit.LoginManager().logOut()
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    //want to set nav.modalPresentationStyle to fullscreen - if not specified this way controller pops
                    //up as a card and the user can dismiss it even if they arent logged in
                    nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav, animated: true)
                    
                }
                catch {
                    print("error signing out..try again")
                }
                
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Cancel",
                                                style: .cancel,
                                                handler: nil))
            
            strongSelf.present(actionSheet, animated: true)
            
        }))
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
    }
    
    //profile page header with profile pic 
    func createTableHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 200))
        
        headerView.backgroundColor = .systemBackground
        
        
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2,
                                                  y: (headerView.height - 150)/2,
                                                  width: 150,
                                                  height: 150))
        
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.gray.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        headerView.addSubview(imageView)
        
        StorageManager.sharedStorageObj.downloadURL(for: path, completion: { [weak self ] result in
            switch result {
            case .success(let url):
                self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                    print("failed to get downloaded URL: \(error) ")
            }
        })
        return headerView
    }
    
    func downloadImage(imageView: UIImageView, url: URL) {
        URLSession.shared.dataTask(with: url, completionHandler: { data, _, error in
            guard let data = data, error == nil else {
                return
            }
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
        }).resume()
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier,
                                                 for: indexPath) as! ProfileTableViewCell
        
        cell.setUp(with: cellModel)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indextPath: IndexPath) {
        tableView.deselectRow(at: indextPath, animated: true)
      
        data[indextPath.row].handler?()
    }
}

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with cellModel: ProfileCellModel) {
        
        self.textLabel?.text = cellModel.title
        
        switch cellModel.cellModelType {
        case .info:
            //text is already aligned left so i dont really need this
            self.textLabel?.textAlignment = .center
            selectionStyle = .none
        case .logout:
            self.textLabel?.textColor = .red
            self.textLabel?.textAlignment = .center
        }
        
    }
}
