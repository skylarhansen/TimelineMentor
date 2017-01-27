//
//  PostDetailTableViewController.swift
//  Timeline
//
//  Created by Skylar Hansen on 12/23/16.
//  Copyright © 2016 Skylar Hansen. All rights reserved.
//

import UIKit

class PostDetailTableViewController: UITableViewController {
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var followPostButton: UIBarButtonItem!
    
    var post: Post?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(postCommentsChanged(_:)), name: PostController.PostCommentsChangedNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let post = post {
            update(withPost: post)
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @IBAction func commentButtonTapped(_ sender: Any) {
        
        var commentTextField: UITextField?
        
        let alertController = UIAlertController(title: "New Comment", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter new comment here"
            commentTextField = textField
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
            guard let commentText = commentTextField?.text,
                let post = self.post,
                !commentText.isEmpty else { return }
            PostController.sharedController.add(comment: commentText, toPost: post)
            self.tableView.reloadData()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func shareButtonTapped(_ sender: Any) {
        
        guard let photo = post?.photo,
            let comment = post?.comments.first?.text else { return }
        
        let activityVC = UIActivityViewController(activityItems: [photo, comment], applicationActivities: nil)
        
        present(activityVC, animated: true, completion: nil)
    }
    
    @IBAction func followButtonTapped(_ sender: Any) {
        
        guard let post = post else { return }
        
        PostController.sharedController.togglePostCommentSubscription(post: post) { (_, _, _) in
            
            DispatchQueue.main.async {
                self.update(withPost: post)
            }
        }
    }
    
    // MARK: - Custom functions
    
    func update(withPost post: Post) {
        postImageView.image = post.photo
        
        PostController.sharedController.checkSubscriptionToPostComments(post: post) { (subscribed) in
            DispatchQueue.main.async {
                self.followPostButton.title = subscribed ? "Unfollow Post" : "Follow Post"
            }
        }
        
        tableView.reloadData()
    }
    
    func postCommentsChanged(_ notification: Notification) {
        guard let post = post,
            let notificationPost = notification.object as? Post, notificationPost === post else { return }
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return post?.comments.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell", for: indexPath)
        
        guard let comment = post?.comments[indexPath.row] else { return UITableViewCell() }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateString = dateFormatter.string(from: comment.timestamp)
        
        cell.textLabel?.text = comment.text
        cell.detailTextLabel?.text = dateString
        
        return cell
    }
}
