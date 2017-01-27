//
//  CloudKitSyncable.swift
//  Timeline
//
//  Created by Skylar Hansen on 12/25/16.
//  Copyright © 2016 Skylar Hansen. All rights reserved.
//

import Foundation
import CloudKit

protocol CloudKitSyncable {
    
    init?(record: CKRecord)
    
    var cloudKitRecordID: CKRecordID? { get set }
    var recordType: String { get }
}

extension CloudKitSyncable {
    
    var isSynced: Bool {
        return cloudKitRecordID != nil
    }
    
    var cloudKitReference: CKReference? {
        guard let cloudKitRecordID = cloudKitRecordID else { return nil }
        return CKReference(recordID: cloudKitRecordID, action: .none)
    }
}
