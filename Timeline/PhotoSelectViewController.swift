//
//  PhotoSelectViewController.swift
//  Timeline
//
//  Created by Skylar Hansen on 12/24/16.
//  Copyright © 2016 Skylar Hansen. All rights reserved.
//

import UIKit

class PhotoSelectViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    weak var delegate: PhotoSelectViewControllerDelegate?

    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var selectPhotoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func selectPhotoButtonTapped(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        
        let alert = UIAlertController(title: "Select Photo Location", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { (_) -> Void in
                imagePickerController.sourceType = .photoLibrary
                self.present(imagePickerController, animated: true, completion: nil)
            }))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (_) -> Void in
                imagePickerController.sourceType = .camera
                self.present(imagePickerController, animated: true, completion: nil)
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            
            delegate?.photoSelectViewControllerSelected(image: image)
            selectPhotoButton.setTitle("", for: .normal)
            postImageView.image = image
        }
    }
}

protocol PhotoSelectViewControllerDelegate: class {
    func photoSelectViewControllerSelected(image: UIImage)
}
