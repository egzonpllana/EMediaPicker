//
//  MediaPickerPermissionsViewController.swift
//  EMediaPicker
//
//  Created by Egzon Pllana on 11/18/20.
//  Copyright © 2020 Native Coders. All rights reserved.
//

import UIKit
import Photos

protocol RequestPermissionsDelegate: class {
    func didAllowAllPermissions()
    func missingPermissions(missingPermissions: [MediaPickerPermissions])
}

class MediaPickerPermissionsViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var allViewContentView: UIRoundedView!
    @IBOutlet weak var accessButtonsStackView: UIStackView!
    @IBOutlet weak var allSetStackView: UIStackView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var allSetBottomConstraint: NSLayoutConstraint!

    // MARK: - Properties
    weak var presentingFromViewController: UIViewController?
    weak var requestPermissionsDelegate: RequestPermissionsDelegate?
    var shouldDimSelfView: Bool = true
    var bottomSafeAreaHeight: CGFloat?

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Gesture recognizer to drag down the view
        let gestureRecognizer = UIPanGestureRecognizer(target: self,
                                                       action: #selector(panGestureRecognizerHandler(_:)))
        view.addGestureRecognizer(gestureRecognizer)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Dim background view when presented picker view
        if shouldDimSelfView {
            dimBackgroundView(dim: true)
        }

        // Manage buttons visibility
        managePermissionButtonsState()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Fix drag down misplacing issues
        if bottomSafeAreaHeight == nil {
            bottomSafeAreaHeight = view.safeAreaInsets.bottom
            bottomConstraint.constant = view.safeAreaInsets.bottom + 4
            allSetBottomConstraint.constant = view.safeAreaInsets.bottom + 4
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove dim background color
        if shouldDimSelfView {
            UIView.animate(withDuration: 0.2) {
                self.dimBackgroundView(dim: false)
            }
        }
    }

    // MARK: - Methods

    private func managePermissionButtonsState() {
        let cameraPermission = (AVCaptureDevice.authorizationStatus(for: AVMediaType.video) == .authorized)
        let libraryPermission = (PHPhotoLibrary.authorizationStatus() == .authorized)
        let microphonePermission = (AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) == .authorized)

        cameraButton.isEnabled = !cameraPermission
        cameraButton.setTitleColor(.lightGray, for: .disabled)

        libraryButton.isEnabled = !libraryPermission
        libraryButton.setTitleColor(.lightGray, for: .disabled)

        microphoneButton.isEnabled = !microphonePermission
        microphoneButton.setTitleColor(.lightGray, for: .disabled)

        if (cameraPermission) && (libraryPermission) && (microphonePermission) {
            accessButtonsStackView.isHidden = true
            self.allSetStackView.alpha = 0
            self.allSetStackView.isHidden = false
            UIView.animate(withDuration: 0.5) {
                self.allSetStackView.alpha = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.dismiss(animated: true) {
                        self.requestPermissionsDelegate?.didAllowAllPermissions()
                    }
                }
            }
        } else {
            var permissionList: [MediaPickerPermissions] = []
            permissionList.forEach { _ in
                if cameraPermission == false {
                    permissionList.append(.camera)
                } else if libraryPermission == false {
                    permissionList.append(.library)
                } else if microphonePermission == false {
                    permissionList.append(.microphone)
                }
            }
            requestPermissionsDelegate?.missingPermissions(missingPermissions: permissionList)
        }
    }

    private func dimBackgroundView(dim: Bool) {
        let dimViewControllersAlpha: CGFloat = dim ? 0.65 : 1
        let parentViewControllersAlpha: CGFloat = dim ? 0 : 1

        presentingFromViewController?.navigationController?.viewControllers.forEach({ (viewcontroller) in
            viewcontroller.view.alpha = parentViewControllersAlpha
        })

        presentingFromViewController?.navigationController?.navigationBar.alpha = parentViewControllersAlpha
        presentingFromViewController?.presentingViewController?.view.alpha = parentViewControllersAlpha

        self.presentingFromViewController?.parent?.view.alpha = dimViewControllersAlpha
        self.presentingViewController?.view.alpha = dimViewControllersAlpha
    }

    private func grantCameraPermission() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthorizationStatus {
        case .authorized:
            self.managePermissionButtonsState()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (_) -> Void in
                DispatchQueue.main.async {
                    self.managePermissionButtonsState()
                }
            })
        case .denied, .restricted:
            self.showPhoneSettings()
        default:
            fatalError("Camera Authorization Status not handled!")
        }
    }

    private func grantPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            self.managePermissionButtonsState()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { _ in
                DispatchQueue.main.async {
                    self.managePermissionButtonsState()
                }
            }

        case .denied, .restricted:
            self.showPhoneSettings()
        default:
            debugPrint("Status not categorized: ", status.rawValue)
        }
    }

    private func grantMicrophonePermission() {
        let microphoneAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        if microphoneAuthorizationStatus == .notDetermined {
            /// Ask permissions
            let recordPermission = AVAudioSession.sharedInstance().recordPermission

            switch recordPermission {
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission({ _ in
                    DispatchQueue.main.async {
                        self.managePermissionButtonsState()
                    }
                })
            case .granted:
                self.managePermissionButtonsState()
            case .denied:
                self.showPhoneSettings()
            @unknown default:
                self.showPhoneSettings()
            }
        }
    }

    private func showPhoneSettings() {
        let alertController = UIAlertController(title: "Permission Error",
                                                message: "Permission denied, please allow our app permission through Settings in your phone if you want to use our service.", preferredStyle: .alert)
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

    @IBAction func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        guard let rootView = view, let rootWindow = rootView.window else { return }
        let rootWindowHeight: CGFloat = rootWindow.frame.size.height

        let touchPoint = sender.location(in: view?.window)
        var initialTouchPoint = CGPoint.zero
        let blankViewHeight =  (rootWindowHeight - allViewContentView.frame.size.height)
        let dismissDragSize: CGFloat = allViewContentView.frame.size.height/2

        switch sender.state {
        case .began:
            initialTouchPoint = touchPoint
        case .changed:
            // dynamic alpha
            if touchPoint.y > (initialTouchPoint.y + blankViewHeight) { // change dim background (alpha)
                view.frame.origin.y = (touchPoint.y - blankViewHeight) - initialTouchPoint.y
            }

        case .ended, .cancelled:
            if touchPoint.y - initialTouchPoint.y > (dismissDragSize + blankViewHeight) {
                dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.frame = CGRect(x: 0,
                                             y: 0,
                                             width: self.view.frame.size.width,
                                             height: self.view.frame.size.height)
                })
                // alpha = 1
            }
        case .failed, .possible:
            break
        @unknown default:
            debugPrint("Unknown UIGestureRecognizer state -> \(sender.state)", #function)

        }
    }

    @IBAction func accessButtonPressed(_ sender: Any) {
        guard let button = sender as? UIButton else { return }

        // Tags: 1 - camera, 2 - library, 3 - microphone

        switch button.tag {
        case 1:
            grantCameraPermission()
        case 2:
            grantPhotoLibraryPermission()
        case 3:
            grantMicrophonePermission()
        default:
            debugPrint("Unknown button tag-> \(button.tag)", #function)
        }
    }

    @IBAction func blackViewPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
