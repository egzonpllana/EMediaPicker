//
//  MediaPickerRootViewController.swift
//  EMediaPicker
//
//  Created by Egzon Pllana on 11/18/20.
//  Copyright © 2020 Native Coders. All rights reserved.
//

// TODO: Do not forgot to add in Info.plist these keys
// Privacy - Photo Library Usage Description
// Privacy - Camera Usage Description
// Privacy - Microphone Usage Description

import UIKit
import Photos

enum MediaPickerSegues: String {
    case mediaPickerSegue
    case permissionSegue
}

class MediaPickerRootViewController: UIViewController {

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    // MARK: - Methods

    private func presentMediaPicker() {
        let cameraPermission = (AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized)
        let libraryPermission = (PHPhotoLibrary.authorizationStatus() == .authorized)
        let microphonePermission = (AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) == .authorized)

        if (cameraPermission) && (libraryPermission) && (microphonePermission) {
            self.performSegue(withIdentifier: MediaPickerSegues.mediaPickerSegue.rawValue, sender: nil)
        } else {
            self.performSegue(withIdentifier: MediaPickerSegues.permissionSegue.rawValue, sender: nil)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mediaPickerRootViewController = segue.destination as? MediaPickerViewController {
            mediaPickerRootViewController.delegate = self

            // Configure Photos Library options
            // mediaPickerRootViewController.canPickVideos = false
            // mediaPickerRootViewController.canTakeVideo = false
            // mediaPickerRootViewController.maximumImagesSelection = 50
            // mediaPickerRootViewController.maximumVideoSelection = 10
        } else if let mediaAccessControlViewController = segue.destination as? MediaPickerPermissionsViewController {
            mediaAccessControlViewController.presentingFromViewController = self
            mediaAccessControlViewController.requestPermissionsDelegate = self
        }
    }

    // MARK: - Actions

    @IBAction func showMediaPicker(_ sender: Any) {
        presentMediaPicker()
    }
}

extension MediaPickerRootViewController: MediaPickerDelegate {
    func photoLibraryDidSelectAssets(assets: [MediaAsset]) {
        print("PhotoLibrary did select assets! Assets: ", assets)
    }

    func photoLibraryDidDismissPhotoLibraryPicker() {
        //
    }

    func cameraDidCapture(image: UIImage) {
        if let imageData = image.jpegData(compressionQuality: 0.2) {
            print("Camera did capture image! Image data: ", imageData)
        }
    }

    func cameraDidCapture(videoUrl: URL) {
        print("Camera did capture video. Video path: ", videoUrl)
    }

    func cameraDidDismissCameraSession() {
        //
    }
}

extension MediaPickerRootViewController: RequestPermissionsDelegate {
    func didAllowAllPermissions() {
        self.performSegue(withIdentifier: MediaPickerSegues.mediaPickerSegue.rawValue, sender: nil)
    }

    func missingPermissions(missingPermissions: [MediaPickerPermissions]) {
        print("User has denied permissions: ", missingPermissions.forEach { print($0.rawValue, ", ") })
    }
}
