//
//  PostTableViewCell.swift
//  Timeline
//
//  Created by Skylar Hansen on 12/23/16.
//  Copyright © 2016 Skylar Hansen. All rights reserved.
//

import UIKit

class PostTableViewCell: UITableViewCell {

    @IBOutlet weak var postImageView: UIImageView!
   
    func update(withPost post: Post) {
        postImageView.image = post.photo
    }

    
}
