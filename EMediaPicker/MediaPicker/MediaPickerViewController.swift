//
//  MediaPickerViewController.swift
//  EMediaPicker
//
//  Created by Egzon Pllana on 11/18/20.
//  Copyright © 2020 Native Coders. All rights reserved.
//

// The way of managing child view controllers is
// inspired by Bart Jacobs from CocoaCasts:
// https://cocoacasts.com/managing-view-controllers-with-container-view-controllers/

import UIKit

private enum MediaPickerController {
    case photoLibraryPicker
    case cameraSession
}

protocol MediaPickerDelegate: class {

    // Photo Library Picker
    func photoLibraryDidSelectAssets(assets: [MediaAsset])
    func photoLibraryDidDismissPhotoLibraryPicker()

    // Camera Session
    func cameraDidCapture(image: UIImage)
    func cameraDidCapture(videoUrl: URL)
    func cameraDidDismissCameraSession()
}

class MediaPickerViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: MediaPickerDelegate? // Avoid memory retain cycles
    
    var canPickVideos: Bool = true
    var canTakeVideo: Bool = true
    var maximumImagesSelection: Int = 50
    var maximumVideoSelection: Int = 10

    // MARK: - Child view controllers

    private lazy var photoLibraryPickerViewController: PhotoLibraryPickerViewController = {
        // Instantiate view controller
        let photoLibraryPickerViewController = PhotoLibraryPickerViewController.instantiate()

        // Manage can pick videos property
        photoLibraryPickerViewController.canPickVideos = self.canPickVideos
        photoLibraryPickerViewController.maximumImagesSelection = self.maximumImagesSelection
        photoLibraryPickerViewController.maximumImagesSelection = self.maximumImagesSelection

        // Add View Controller as Child View Controller
        self.add(asChildViewController: photoLibraryPickerViewController)

        return photoLibraryPickerViewController
    }()

    private lazy var cameraSessionViewController: CameraSessionViewController = {
        // Instantiate view controller
        let cameraSessionViewController = CameraSessionViewController.instantiate()

        // Manage can pick videos property
        cameraSessionViewController.canTakeVideo = self.canTakeVideo

        // Add View Controller as Child View Controller
        self.add(asChildViewController: cameraSessionViewController)

        return cameraSessionViewController
    }()

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        // Set starting viewcontroller
        switchTo(.photoLibraryPicker)
    }

    // MARK: - Methods

    private func add(asChildViewController viewController: UIViewController) {
        // Add Child View as Subview
        view.addSubview(viewController.view)

        // Configure Child View
        if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            // Fix issue with safe area
            // view.safeAreaInsets is returing 0.0 for devices like iphoneX
            let topPadding = window.safeAreaInsets.top
            let bottomPadding = window.safeAreaInsets.bottom
            viewController.view.frame = CGRect(x: view.bounds.minX, y: view.bounds.minY+topPadding, width: view.bounds.width, height: view.bounds.height-bottomPadding-topPadding)
        } else {
            viewController.view.frame = view.bounds
        }

        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Add viewcontrollers delegate
        if let photoLibraryPickerViewController = viewController as? PhotoLibraryPickerViewController {
            photoLibraryPickerViewController.delegate = self
        } else if let cameraSessionViewController = viewController as? CameraSessionViewController {
            cameraSessionViewController.delegate = self
        }
    }

    private func remove(asChildViewController viewController: UIViewController) {
        // Notify Child View Controller
        // First, we notify the child view controller that it is about to
        // be removed from the container view controller by sending it a message of
        viewController.willMove(toParent: nil)

        // Remove Child View From Superview
        viewController.view.removeFromSuperview()

        // Notify Child View Controller
        viewController.removeFromParent()
    }

    private func switchTo(_ mediaPickerViewController: MediaPickerController) {
        // we add or remove the child view controllers, depending on the
        // segment that is currently selected.

        if mediaPickerViewController == .photoLibraryPicker {
            remove(asChildViewController: cameraSessionViewController)
            add(asChildViewController: photoLibraryPickerViewController)

            // Update background view to match design of
            // photoLibrary picker viewcontroller
            self.view.backgroundColor = .white
        } else if mediaPickerViewController == .cameraSession {
            remove(asChildViewController: photoLibraryPickerViewController)
            add(asChildViewController: cameraSessionViewController)

            // Update background view to match design of
            // camera session viewcontroller
            self.view.backgroundColor = .black
        }
    }
}

// MARK: - CameraSessionDelegate

extension MediaPickerViewController: CameraSessionDelegate {
    func didCapture(image: UIImage) {
        self.dismiss(animated: true) {
            self.delegate?.cameraDidCapture(image: image)
        }
    }

    func didCapture(video videoURL: URL) {
        self.dismiss(animated: true) {
            self.delegate?.cameraDidCapture(videoUrl: videoURL)
        }
    }

    func didPressPhotoLibraryButton() {
        switchTo(.photoLibraryPicker)
    }

    func didDismissCameraSession() {
        self.dismiss(animated: true) {
            self.delegate?.cameraDidDismissCameraSession()
        }
    }
}

// MARK: - PhotoLibraryPickerDelegate

extension MediaPickerViewController: PhotoLibraryPickerDelegate {
    func didFinishSelectingAssets(selectedAssets assets: [MediaAsset]) {
        self.dismiss(animated: true) {
            self.delegate?.photoLibraryDidSelectAssets(assets: assets)
        }
    }

    func didDismissPhotoLibraryPicker() {
        self.dismiss(animated: true) {
            self.delegate?.photoLibraryDidDismissPhotoLibraryPicker()
        }
    }

    func didPressCameraButton() {
        switchTo(.cameraSession)
    }
}
