//
//  CameraPermissionsViewController.swift
//  CameraSession
//
//  Created by Egzon Pllana on 12/24/19.
//  Copyright © 2019 Native Coders. All rights reserved.
//

/* Info.plist
 Privacy - Camera Usage Description
 Privacy - Photo Library Usage Description
 Privacy - Microphone Usage Description
 */

import UIKit
import AVFoundation
import Photos

private enum CameraPermissionType: Int {
    case camera = 1
    case library = 2
    case microphone = 3
}

class CameraPermissionsViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var buttonsStackView: UIStackView!
    @IBOutlet weak var cameraPermissionsButton: UIButton!
    @IBOutlet weak var libraryPermissionButton: UIButton!
    @IBOutlet weak var microphonePermissionButton: UIButton!
    @IBOutlet weak var letsGoButton: UIButton!

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Manage ask for permissions buttons visibility
        setupButtonsVisibility()
    }

    // MARK: - Functions

    private func askCameraPerssion(withType type: CameraPermissionType) {
        /// https://stackoverflow.com/a/41721013/7987502

        switch type {
        case .camera: grantCameraPermission()
        case .library: grantPhotosLibraryPermission()
        case .microphone: grantMicrophonePermission()
        }
    }

    private func setupButtonsVisibility() {
        /// update ui in main queue asynchronous
        DispatchQueue.main.async {
            /// camera button visibity state
            let cameraAuthorizationStatus = (AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized) ? true : false
            self.cameraPermissionsButton.isHidden = cameraAuthorizationStatus

            /// microphone button visibity state
            let microphoneAuthorizationStatus = (AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) == .authorized) ? true : false
            self.microphonePermissionButton.isHidden = microphoneAuthorizationStatus

            /// photo library visibity state
            let photosAuthorizationStatus = (PHPhotoLibrary.authorizationStatus() == .authorized) ? true : false
            self.libraryPermissionButton.isHidden = photosAuthorizationStatus

            /// letsGo button visibity state
            self.letsGoButton.isHidden = !(cameraAuthorizationStatus && microphoneAuthorizationStatus && photosAuthorizationStatus)
        }
    }

    private func grantCameraPermission() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthorizationStatus {
        case .authorized:
            print("present you viewcontroller")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
                if granted == true {
                    /// User granted
                    self.setupButtonsVisibility()
                }
            })
        case .denied, .restricted:
            self.showPhoneSettings()
        default:
            fatalError("Camera Authorization Status not handled!")
        }
    }

    private func grantPhotosLibraryPermission() {
        let photosAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        if photosAuthorizationStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization({status in
                if status == .authorized {
                    /// User granted
                    self.setupButtonsVisibility()
                }
            })
        } else {
            self.showPhoneSettings()
        }
    }

    private func grantMicrophonePermission() {
        let microphoneAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        if microphoneAuthorizationStatus == .notDetermined {
            /// Ask permissions
            let recordPermission = AVAudioSession.sharedInstance().recordPermission
            if recordPermission == .undetermined {
                AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
                    if granted {
                        /// User granted
                        self.setupButtonsVisibility()
                    }
                })
            }
        } else {
            self.showPhoneSettings()
        }
    }

    private func showPhoneSettings() {
        let alertController = UIAlertController(title: "Permission Error", message: "Permission denied, please allow our app permission through Settings in your phone if you want to use our service.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    /// Handle user opened phone Settings
                })
            }
        })

        present(alertController, animated: true)
    }

    // MARK: - Actions
    @IBAction func unwindToCameraPermissionsViewController(segue: UIStoryboardSegue) {}

    @IBAction func permissionButtonPressed(_ sender: Any) {
        guard let button = sender as? UIButton else { return }
        let tag = button.tag /* buttons tag in storyboard: 1(camera), 2(library), 3(microphone)  */

        if let permissionType = CameraPermissionType(rawValue: tag) {
            askCameraPerssion(withType: permissionType)
        } else {
            assertionFailure("Failed to get permission value from CameraPermissionType!")
        }
    }
    
}
