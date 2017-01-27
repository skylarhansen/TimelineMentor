//
//  SearchableRecord.swift
//  Timeline
//
//  Created by Skylar Hansen on 12/24/16.
//  Copyright © 2016 Skylar Hansen. All rights reserved.
//

import Foundation

protocol SearchableRecord {
    func matches(searchTerm: String) -> Bool
}
