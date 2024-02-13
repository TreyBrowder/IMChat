//
//  NewConversationViewController.swift
//  IMChat
//
//  Created by Trey Browder on 1/29/24.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    private var usersArr = [[String: String]]()
    private var hasFetched = false
    private var results = [SearchResult]()
    
    public var completion: ((SearchResult) -> (Void))?
    
    
    private let spinner = JGProgressHUD(style: .dark)

    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search for Users"
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No results"
        label.textAlignment = .center
        label.textColor = .red
        label.font = .systemFont(ofSize: 21, weight: .medium)
        
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissSelf))
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width/4,
                                      y: (view.height-200)/2,
                                      width: view.width/2,
                                      height: 200)
    }
    
    @objc private func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }

}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row].name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //start conversation
        let targetUserData = results[indexPath.row]
        
        dismiss(animated: true, completion: { [weak self ] in
            self?.completion?(targetUserData)
        })
    }
    
}

extension NewConversationViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        //get rid of keyboard
        searchBar.resignFirstResponder()
        
        results.removeAll()
        spinner.show(in: view)
        
        self.searchUsers(query: text)
    }
    
    ///get the results from search
    func searchUsers(query: String) {
        //check arry first results
        if hasFetched {
            //if it does - filter
            filterUsers(with: query)
        }
        else {
            //if not - fetch then filt
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.usersArr = usersCollection
                    self?.filterUsers(with: query)
                case .failure(let err):
                    print("failed to get users: \(err)")
                }
            })
        }
    }
    
    ///filter out thst has the prefix of search term
    func filterUsers(with term: String) {
        //update UI - show result of search or show no results label
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        //dismiss search spinner
        self.spinner.dismiss()
        
        //dont want to allow user to start conversation with themselves
        let resultsArr: [SearchResult] = self.usersArr.filter({
            guard let email = $0["email"], email != safeEmail else {
                return false
            }
            
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            
            return name.hasPrefix(term.lowercased())
        }).compactMap ({
            
            guard let email = $0["email"],
            let name = $0["name"] else {
                //failed
                print("failed to return name with email with SearchResult Obj")
                return nil
            }
            
            return SearchResult(name: name, email: email)
        })
        
        self.results = resultsArr
        updateUI()
    }
        
    ///upodate UI based on results
    func updateUI() {
        if results.isEmpty {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        }
        else {
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

struct SearchResult {
    let name: String
    let email: String
}
