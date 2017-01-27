//
//  AddPostTableViewController.swift
//  Timeline
//
//  Created by Skylar Hansen on 12/23/16.
//  Copyright © 2016 Skylar Hansen. All rights reserved.
//

import UIKit

class AddPostTableViewController: UITableViewController, UITextFieldDelegate, PhotoSelectViewControllerDelegate {
    
    @IBOutlet weak var captionTextField: UITextField!
    
    var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        captionTextField.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func addPostButtonTapped(_ sender: Any) {
        
        if let image = image,
            let caption = captionTextField.text,
            !caption.isEmpty {
            PostController.sharedController.create(postWithImage: image, andCaption: caption)
            dismiss(animated: true, completion: nil)
        }
        
        guard let caption = captionTextField.text else { return }
        
        if image == nil || caption.isEmpty {
            let alertController = UIAlertController(title: "Missing Information", message: "Make sure you have selected an image and entered a caption", preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alertController.addAction(dismissAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - PhotoSelectViewControllerDelegate
    
    func photoSelectViewControllerSelected(image: UIImage) {
        self.image = image
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photoSelectEmbedSegue" {
            guard let photoSelectVC = segue.destination as? PhotoSelectViewController else { return }
            photoSelectVC.delegate = self
        }
    }
}

