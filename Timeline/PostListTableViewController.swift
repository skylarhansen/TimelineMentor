//
//  PostListTableViewController.swift
//  Timeline
//
//  Created by Skylar Hansen on 12/23/16.
//  Copyright © 2016 Skylar Hansen. All rights reserved.
//

import UIKit

class PostListTableViewController: UITableViewController, UISearchResultsUpdating {
    
    var searchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestFullSync()
        setUpSearchController()
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(postsChanged(_:)), name: PostController.PostsChangedNotification, object: nil)
    }
    
    // MARK: - Actions
    
    @IBAction func refreshControlPulled(_ sender: Any) {
        
        requestFullSync {
            self.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: -
    
    func postsChanged(_ notification: Notification) {
        tableView.reloadData()
    }
    
    // MARK: - Searching
    
    func setUpSearchController() {
        let resultsController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "resultsController")
        
        searchController = UISearchController(searchResultsController: resultsController)
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.sizeToFit()
        searchController?.hidesNavigationBarDuringPresentation = true
        tableView.tableHeaderView = searchController?.searchBar
        
        definesPresentationContext = true
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        guard let resultsViewController = searchController.searchResultsController as? SearchResultsTableViewController,
            let searchTerm = searchController.searchBar.text?.lowercased(),
            !searchTerm.isEmpty else { return }
        
        let results = PostController.sharedController.posts.filter { $0.matches(searchTerm: searchTerm) }
        
        resultsViewController.resultsArray = results
        resultsViewController.tableView.reloadData()
    }
    
    // MARK: - CloudKit sync
    
    func requestFullSync(completion: (() -> Void)? = nil) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        PostController.sharedController.performFullSync {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            completion?()
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PostController.sharedController.posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "postCell", for: indexPath) as? PostTableViewCell else { return UITableViewCell() }
        
        let post = PostController.sharedController.posts[indexPath.row]
        cell.update(withPost: post)
        
        return cell
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toPostDetail" {
            guard let postDetailTVC = segue.destination as? PostDetailTableViewController,
                let indexPath = tableView.indexPathForSelectedRow else { return }
            let post = PostController.sharedController.posts[indexPath.row]
            postDetailTVC.post = post
        }
        
        if segue.identifier == "toPostDetailFromSearch" {
            guard let postDetailTVC = segue.destination as? PostDetailTableViewController,
                let sender = sender as? PostTableViewCell,
                let searchResultsController = searchController?.searchResultsController as? SearchResultsTableViewController,
                let indexPath = searchResultsController.tableView.indexPath(for: sender),
                let searchTerm = searchController?.searchBar.text?.lowercased() else { return }
            
            let posts = PostController.sharedController.posts.filter { $0.matches(searchTerm: searchTerm) }
            let post = posts[indexPath.row]
            
            postDetailTVC.post = post
        }
    }
}
