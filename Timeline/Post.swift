//
//  Post.swift
//  Timeline
//
//  Created by Skylar Hansen on 12/23/16.
//  Copyright © 2016 Skylar Hansen. All rights reserved.
//

import UIKit
import CloudKit

class Post: CloudKitSyncable {
    
    static let kPhotoData = "photoData"
    static let kTimestamp = "timestamp"
    static let kType = "Post"
    
    let photoData: Data?
    let timestamp: Date
    var comments: [Comment]
    
    var photo: UIImage {
        guard let photoData = photoData,
            let image = UIImage(data: photoData) else { return UIImage() }
        return image
    }
    
    var temporaryPhotoURL: URL {
        let temporaryDirectory = NSTemporaryDirectory()
        let temporaryDirectoryURL = URL(fileURLWithPath: temporaryDirectory)
        let fileURL = temporaryDirectoryURL.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        
        try? photoData?.write(to: fileURL)
        
        return fileURL
    }
    
    init(photoData: Data, timestamp: Date = Date(), comments: [Comment] = []) {
        self.photoData = photoData
        self.timestamp = timestamp
        self.comments = comments
    }
    
    // MARK: - CloudKitSyncable
    
    convenience required init?(record: CKRecord) {
        guard let timestamp = record.creationDate,
            let photoAsset = record[Post.kPhotoData] as? CKAsset,
            let photoData = try? Data(contentsOf: photoAsset.fileURL) else { return nil }
        
        self.init(photoData: photoData, timestamp: timestamp)
        cloudKitRecordID = record.recordID
    }
    
    var recordType: String { return Post.kType }
    var cloudKitRecordID: CKRecordID?
}

// MARK: - SearchableRecord 

extension Post: SearchableRecord {
    
    func matches(searchTerm: String) -> Bool {
        let matchingComments = comments.filter { $0.matches(searchTerm: searchTerm) }
        return !matchingComments.isEmpty
    }
}

// MARK: - CKRecord extension

extension CKRecord {
    convenience init(post: Post) {
        let recordID = CKRecordID(recordName: UUID().uuidString)
        self.init(recordType: post.recordType, recordID: recordID)
        
        self[Post.kTimestamp] = post.timestamp as CKRecordValue?
        self[Post.kPhotoData] = CKAsset(fileURL: post.temporaryPhotoURL)
    }
}




































