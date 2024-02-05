//
//  ProfileViewController.swift
//  IMChat
//
//  Created by Trey Browder on 1/29/24.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    
    let data = ["Log Out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        
        return cell
    }
    
    func tableView(_tableView: UITableView, didSelectRowAt indextPath: IndexPath) {
        tableView.deselectRow(at: indextPath, animated: true)
        
        do {
            try FirebaseAuth.Auth.auth().signOut()
        }
        catch {
            print("error signing out..try again")
        }
    }
}
