//
//  SearchResultsTableViewController.swift
//  Timeline
//
//  Created by Skylar Hansen on 12/23/16.
//  Copyright © 2016 Skylar Hansen. All rights reserved.
//

import UIKit

class SearchResultsTableViewController: UITableViewController {
    
    var resultsArray: [SearchableRecord] = []

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultsArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "resultCell", for: indexPath) as? PostTableViewCell,
        let post = resultsArray[indexPath.row] as? Post else { return UITableViewCell() }

        cell.update(withPost: post)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        self.presentingViewController?.performSegue(withIdentifier: "toPostDetailFromSearch", sender: cell)
    }
}
