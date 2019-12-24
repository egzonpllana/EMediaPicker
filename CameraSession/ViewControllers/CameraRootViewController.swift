//
//  CameraRootViewController.swift
//  CameraSession
//
//  Created by Egzon Pllana on 12/24/19.
//  Copyright © 2019 Native Coders. All rights reserved.
//

import UIKit

class CameraRootViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var headerTitleLabel: UILabel!
    @IBOutlet weak var libraryButton: UIButton!
    @IBOutlet weak var recordVideoButton: UIButton!
    @IBOutlet weak var takePhotoButton: UIButton!
    @IBOutlet weak var viewControllersView: UIView!

    weak var onTouchRecordViewControllerDelegate: OnTouchRecordViewController?

    // MARK: - Child view controllers

    private lazy var assetsPickerViewController: AssetsPickerRootViewController = {
        // Instantiate View Controller
        var viewController = AssetsPickerRootViewController.instantiate()

        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)

        return viewController
    }()

    private lazy var onTouchRecordViewController: OnTouchRecordViewController = {
        // Instantiate View Controller
        var viewController = OnTouchRecordViewController.instantiate()

        // Add View Controller as Child View Controller
        self.add(asChildViewController: viewController)

        return viewController
    }()

    // MARK: - View life cycles

    override func viewDidLoad() {
        super.viewDidLoad()

        // setup views
        setupViews()

        /// assets is the first viewcontroller to be shown
        libraryButton.isSelected = true
        add(asChildViewController: assetsPickerViewController)

        // Do any additional setup after loading the view.
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

    // MARK: - Functions

    private func add(asChildViewController viewController: UIViewController) {
        // Add Child View as Subview
        viewControllersView.addSubview(viewController.view)

        ///
        if let onTouchRecordVC = viewController as? OnTouchRecordViewController {
            onTouchRecordViewControllerDelegate = onTouchRecordVC
        }

        // Configure Child View
        viewController.view.frame = viewControllersView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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

    private func setupViews() {
        updateView()
    }

    private func updateView() {
        // we add or remove the child view controllers, depending on the
        // segment that is currently selected.

        if libraryButton.isSelected {
            remove(asChildViewController: onTouchRecordViewController)
            add(asChildViewController: assetsPickerViewController)
        } else if recordVideoButton.isSelected || takePhotoButton.isSelected {
            remove(asChildViewController: assetsPickerViewController)
            add(asChildViewController: onTouchRecordViewController)
        }
    }


    // MARK: - Actions

    @IBAction func bottomBarButtonPressed(_ sender: Any) {
        guard let button = sender as? UIButton else { return }

        /// buttons tag in storyboard: 1(library), 2(record video), 3(take photo)
        let tag = button.tag

        libraryButton.isSelected = false
        recordVideoButton.isSelected = false
        takePhotoButton.isSelected = false

        switch tag {
        case 0:
            libraryButton.isSelected = true
            headerTitleLabel.text = "Assets"
        case 1:
            recordVideoButton.isSelected = true
            onTouchRecordViewControllerDelegate?.isTakingVideo = true
            headerTitleLabel.text = "Record Video"
        case 2:
            takePhotoButton.isSelected = true
            onTouchRecordViewControllerDelegate?.isTakingVideo = false
            headerTitleLabel.text = "Take Photo"
        default:
            print("Button tag not handle. Tag: ", tag)
        }

        updateView()
    }

}
