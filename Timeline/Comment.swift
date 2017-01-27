//
//  Comment.swift
//  Timeline
//
//  Created by Skylar Hansen on 12/23/16.
//  Copyright © 2016 Skylar Hansen. All rights reserved.
//

import Foundation
import CloudKit

class Comment: CloudKitSyncable {
    
    static let kType = "Comment"
    static let kTimestamp = "timestamp"
    static let kText = "text"
    static let kPost = "post"
    
    let text: String
    let timestamp: Date
    var post: Post?
    
    init(text: String, timestamp: Date = Date(), post: Post?) {
        self.text = text
        self.timestamp = timestamp
        self.post = post
    }
    
    // MARK: - CloudKitSyncable
    
    convenience required init?(record: CKRecord) {
        guard let text = record[Comment.kText] as? String,
            let timestamp = record.creationDate else { return nil }
        
        self.init(text: text, timestamp: timestamp, post: nil)
        cloudKitRecordID = record.recordID
    }
    
    var recordType: String { return Comment.kType }
    var cloudKitRecordID: CKRecordID?
}

// MARK: - SearchableRecord

extension Comment: SearchableRecord {
    func matches(searchTerm: String) -> Bool {
        let searchText = text.lowercased()
        return searchText.contains(searchTerm)
    }
}

// MARK: - CKRecord extension

extension CKRecord {
    convenience init(comment: Comment) {
        guard let post = comment.post else { fatalError("Comment doesn't have a post object") }
        let postRecordID = post.cloudKitRecordID ?? CKRecord(post: post).recordID
        let recordID = CKRecordID(recordName: UUID().uuidString)
        self.init(recordType: comment.recordType, recordID: recordID)
        
        self[Comment.kTimestamp] = comment.timestamp as CKRecordValue?
        self[Comment.kText] = comment.text as CKRecordValue?
        self[Comment.kPost] = CKReference(recordID: postRecordID, action: .deleteSelf)
    }
}


