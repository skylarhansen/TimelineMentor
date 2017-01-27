//
//  PostController.swift
//  Timeline
//
//  Created by Skylar Hansen on 12/23/16.
//  Copyright © 2016 Skylar Hansen. All rights reserved.
//

import UIKit
import CloudKit

class PostController {
    
    static let sharedController = PostController()
    static let PostsChangedNotification = Notification.Name("PostsChangedNotification")
    static let PostCommentsChangedNotification = Notification.Name("PostCommentsChangedNotification")
    
    let cloudKitManager: CloudKitManager
    var comments: [Comment] { return posts.flatMap { $0.comments } }
    var isSyncing: Bool = false
    
    var posts: [Post] = [] {
        didSet {
            DispatchQueue.main.async {
                let notificationCenter = NotificationCenter.default
                notificationCenter.post(name: PostController.PostsChangedNotification, object: self)
            }
        }
    }
    
    init() {
        cloudKitManager = CloudKitManager()
        performFullSync()
        subscribeToNewPosts { (success, error) in
            if success {
                print("Successfully subscribed to new posts.")
            }
        }
    }
    
    func create(postWithImage image: UIImage, andCaption caption: String) {
        
        guard let data = UIImageJPEGRepresentation(image, 0.8) else { return }
        let post = Post(photoData: data)
        posts.append(post)
        
        let cloudKitRecord = CKRecord(post: post)
        
        cloudKitManager.saveRecord(cloudKitRecord) { (record, error) in
            
            if error != nil {
                print("Unable to save post to CloudKit: \(error?.localizedDescription)")
            }
            
            post.cloudKitRecordID = record?.recordID
            self.add(comment: caption, toPost: post)
        }
    }
    
    func add(comment text: String, toPost post: Post) {
        let comment = Comment(text: text, post: post)
        post.comments.append(comment)
        
        let cloudKitRecord = CKRecord(comment: comment)
        
        DispatchQueue.main.async {
            let notificationCenter = NotificationCenter.default
            notificationCenter.post(name: PostController.PostCommentsChangedNotification, object: post)
        }
        
        cloudKitManager.saveRecord(cloudKitRecord) { (record, error) in
            
            if error != nil {
                print("Unable to save comment to CloudKit: \(error?.localizedDescription)")
            }
            comment.cloudKitRecordID = record?.recordID
        }
    }
    
    // MARK: - CloudKit sync
    
    func recordsOf(type: String) -> [CloudKitSyncable] {
        switch type {
        case Post.kType:
            return posts.flatMap { $0 as CloudKitSyncable }
        case Comment.kType:
            return comments.flatMap { $0 as CloudKitSyncable }
        default:
            return []
        }
    }
    
    func synced(recordsOfType type: String) -> [CloudKitSyncable] {
        return recordsOf(type: type).filter { $0.isSynced }
    }
    
    func unsynced(recordsOfType type: String) -> [CloudKitSyncable] {
        return recordsOf(type: type).filter { !$0.isSynced }
    }
    
    func performFullSync(completion: (() -> Void)? = nil) {
        
        guard !isSyncing else { completion?(); return }
        
        isSyncing = true
        pushChangesToCloudKit { (success, error) in
            if success {
                self.fetchNewRecords(ofType: Post.kType, completion: {
                    self.fetchNewRecords(ofType: Comment.kType, completion: {
                        self.isSyncing = false
                        
                        completion?()
                    })
                })
            }
        }
    }
    
    // MARK: - CloudKit fetching
    
    func fetchNewRecords(ofType type: String, completion: @escaping () -> Void) {
        
        var referencesToExclude: [CKReference] = []
        var predicate: NSPredicate?
        // This gives me references that have already been synced to CK
        referencesToExclude = synced(recordsOfType: type).flatMap { $0.cloudKitReference }
        // Don't give me any records that have record IDs of those that have already been synced
        predicate = NSPredicate(format: "NOT(recordID IN %@)", argumentArray: [referencesToExclude])
        
        if referencesToExclude.isEmpty  {
            predicate = NSPredicate(value: true)
        }
        
        cloudKitManager.fetchRecordsWithType(type, predicate: predicate!, recordFetchedBlock: { (record) in
            switch type {
            case Post.kType:
                if let post = Post(record: record) {
                    self.posts.append(post)
                }
            case Comment.kType:
                guard let postReference = record[Comment.kPost] as? CKReference,
                    let postIndex = self.posts.index(where: { $0.cloudKitRecordID == postReference.recordID }),
                    let comment = Comment(record: record) else { return }
                let post = self.posts[postIndex]
                post.comments.append(comment)
                comment.post = post
            default:
                return
            }
        }) { (records, error) in
            if error != nil {
                print("Error fetching new records of \(type) from CloudKit: \(error?.localizedDescription)")
            }
            completion()
        }
    }
    
    func pushChangesToCloudKit(completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        
        guard let unsyncedPosts = unsynced(recordsOfType: Post.kType) as? [Post],
            let unsyncedComments = unsynced(recordsOfType: Comment.kType) as? [Comment] else { return }
        
        var unsavedObjectsByRecord: [CKRecord:CloudKitSyncable] = [:]
        
        for post in unsyncedPosts {
            unsavedObjectsByRecord[CKRecord(post: post)] = post
        }
        
        for comment in unsyncedComments {
            unsavedObjectsByRecord[CKRecord(comment: comment)] = comment
        }
        
        let unsavedRecords = Array(unsavedObjectsByRecord.keys)
        
        cloudKitManager.saveRecords(unsavedRecords, perRecordCompletion: { (record, error) in
            
            guard let record = record else { return }
            unsavedObjectsByRecord[record]?.cloudKitRecordID = record.recordID
            
        }) { (records, error) in
            
            var success = false
            
            if records != nil {
                success = true
            }
            
            completion(success, error)
        }
    }
    
    // MARK: - Subscriptions
    
    func subscribeToNewPosts(completion: ((_ success: Bool, _ error: Error?) -> Void)?) {
        
        let predicate = NSPredicate(value: true)
        
        cloudKitManager.subscribe(Post.kType, predicate: predicate, subscriptionID: "allPosts", contentAvailable: true, options: .firesOnRecordCreation) { (subscription, error) in
            
            let success = subscription != nil && error == nil
            completion?(success, error)
        }
    }
    
    func addSubscriptionToPostComments(post: Post, alertBody: String?, completion: ((_ success: Bool, _ error: Error?) -> Void)?) {
        
        guard let recordID = post.cloudKitRecordID else { return }
        
        let predicate = NSPredicate(format: "post == %@", argumentArray: [recordID])
        
        cloudKitManager.subscribe(Comment.kType, predicate: predicate, subscriptionID: recordID.recordName, contentAvailable: true, alertBody: alertBody, desiredKeys: [Comment.kText, Comment.kPost], options: .firesOnRecordCreation) { (subscription, error) in
            
            let success = subscription != nil && error == nil
            completion?(success, error)
        }
    }
    
    func removeSubscriptionToPostComments(post: Post, completion: ((_ success: Bool, _ error: Error?) -> Void)?) {
        
        guard let recordName = post.cloudKitRecordID?.recordName else { return }
        
        cloudKitManager.unsubscribe(recordName) { (subscriptionID, error) in
            
            let success = subscriptionID != nil && error == nil
            completion?(success, error)
        }
    }
    
    func checkSubscriptionToPostComments(post: Post, completion: ((_ subscribed: Bool) -> Void)?) {
        
        guard let recordName = post.cloudKitRecordID?.recordName else { return }
        
        cloudKitManager.fetchSubscription(recordName) { (subscription, error) in
            
            let subscribed = subscription != nil && error == nil
            completion?(subscribed)
        }
    }
    
    func togglePostCommentSubscription(post: Post, completion: ((_ success: Bool, _ isSubscribed: Bool, _ error: Error?) -> Void)?) {
        
        guard let recordName = post.cloudKitRecordID?.recordName else {
            completion?(false, false, nil)
            return
        }
        
        cloudKitManager.fetchSubscription(recordName) { (subscription, error) in
            
            if subscription != nil {
                self.removeSubscriptionToPostComments(post: post, completion: { (success, error) in
                    completion?(success, false, error)
                })
            } else {
                self.addSubscriptionToPostComments(post: post, alertBody: "Someone commented on a post you follow 🐢", completion: { (success, error) in
                    completion?(success, true, error)
                })
            }
        }
    }
}
