//
//  MediaPickerViewController.swift
//  CameraSession
//
//  Created by Egzon Pllana on 12/24/19.
//  Copyright © 2019 Native Coders. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import MobileCoreServices

class MediaPickerViewController: UIViewController, Storyboardable {

    // MARK: - Outlets

    @IBOutlet weak var imagePreview: UIImageView!

    // MARK: - Properties

    /// Storyboardable
    static var storyboardName: String = "Main"

    var choosenImageData: Data? {
        didSet {
            if let imageData = choosenImageData {
                imagePreview.image = UIImage(data: imageData)
            } else {
                print("Image coversion failed!", #line, #function)
            }
        }
    }

    var choosenVideoPath: URL? {
        didSet {
            imagePreview.image = generateThumbnail(path: choosenVideoPath)
        }
    }

    // MARK: - Lazy Properties

    fileprivate lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [(kUTTypeImage as String)]
        imagePicker.allowsEditing = true
        return imagePicker
    }()

    fileprivate lazy var videoPicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [(kUTTypeMovie as String)]
        imagePicker.allowsEditing = true
        return imagePicker
    }()

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: - Functions

    private func presentProfileActionController(title: String, message: String?) {
        // https://www.ioscreator.com/tutorials/record-video-ios-tutorial

        let actionSheet =
            UIAlertController(title: title,
                              message: message,
                              preferredStyle: .actionSheet)

        actionSheet.addAction(
            UIAlertAction(title: "Image from gallery", style: .default, handler: { (_: UIAlertAction) in
                self.imagePicker.sourceType = .photoLibrary
                self.present(self.imagePicker, animated: true, completion: nil)

            }))

        actionSheet.addAction(
            UIAlertAction(title: "Video from gallery", style: .default, handler: { (_: UIAlertAction) in
                self.videoPicker.sourceType = .photoLibrary
                self.present(self.videoPicker, animated: true, completion: nil)

            }))

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(
                UIAlertAction(title: "Take a photo", style: .default, handler: { (_: UIAlertAction) in
                    self.imagePicker.sourceType = .camera
                    self.present(self.imagePicker, animated: true, completion: nil)
                }))

            actionSheet.addAction(
                UIAlertAction(title: "Record a video", style: .default, handler: { (_: UIAlertAction) in
                    self.videoPicker.sourceType = .camera
                    self.present(self.videoPicker, animated: true, completion: nil)
                }))
        }

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(actionSheet, animated: true, completion: nil)
    }

    private func generateThumbnail(path: URL?) -> UIImage? {
        guard let path = path else {
            print("Empty video path! -> ", #line, #function)
            return nil
        }

        // https://stackoverflow.com/a/40987452/7987502
        do {
            let asset = AVURLAsset(url: path, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }

    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            self.performSegue(withIdentifier: "AssetsPickerSegue", sender: nil)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                switch status {
                case .authorized:
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "AssetsPickerSegue", sender: nil)
                    }
                default:
                    print("Authorization not authorized, current status ", status)
                }
            }
            default:
            print("Status not categorized: ", status)
        }
    }

    @IBAction func defaultPickerPressed(_ sender: Any) {
        presentProfileActionController(title: "Select source", message: "Please select your content source type.")
    }
}

// ImagePickerControllerDelegate, NavigationControllerDelegate
extension MediaPickerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        defer {
            picker.dismiss(animated: true)
        }

        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            self.choosenImageData = image.jpeg(.lowest)
        } else if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL {
            self.choosenVideoPath = videoURL as URL
        }
    }
}

// Compress UIImage Quality
extension UIImage {
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }

    /// Returns the data for the specified image in JPEG format.
    /// If the image object’s underlying image data has been purged, calling this function forces that data to be reloaded into memory.
    /// - returns: A data object containing the JPEG data, or nil if there was a problem generating the data. This function may return nil if the image has no data or if the underlying CGImageRef contains data in an unsupported bitmap format.
    func jpeg(_ quality: JPEGQuality) -> Data? {
        return self.jpegData(compressionQuality: quality.rawValue)
    }
}
