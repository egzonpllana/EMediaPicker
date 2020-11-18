//
//  CameraSessionViewController.swift
//  EMediaPicker
//
//  Created by Egzon Pllana on 11/18/20.
//  Copyright © 2020 Native Coders. All rights reserved.
//

import UIKit
import AVFoundation

protocol CameraSessionDelegate: class {
    func didCapture(image: UIImage)
    func didCapture(video videoURL: URL)
    func didPressPhotoLibraryButton()
    func didDismissCameraSession()
}

// TODO: Recording button should have rounded button with red
// to see the user that he is actually recording
// When recording, show recording time on top

class CameraSessionViewController: UIViewController, Storyboardable {

    // MARK: - Storyboardable

    static var storyboardName: String = "CameraSession"

    // MARK: - Outlets

    @IBOutlet weak var torchButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var rotateCameraButton: UIButton!
    @IBOutlet weak var photoLibraryButton: UIButton!
    @IBOutlet weak var cameraPreviewView: UIView!

    // MARK: - Properties

    private let circularProgressViewTag = 100
    var takeVideoLength: TimeInterval = 20.00
    var canTakeVideo: Bool = true

    // TODO: Fix strong reference, should be weak reference
    // swiftlint:disable:next weak_delegate
    var dhCaptureSessionDelegate: DHCaptureSession?
    weak var delegate: CameraSessionDelegate?

    var notActiveButtonImage: UIImage?
    var activeButtonImage: UIImage?

    var isRecording: Bool = false {
        didSet {
            let cameraButtonStateImage = isRecording ? activeButtonImage : notActiveButtonImage
            cameraButton.setImage(cameraButtonStateImage, for: .normal)

            torchButton.isHidden = !isRecording
            rotateCameraButton.isEnabled = !isRecording
        }
    }

    // MARK: - View lifecycles

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraButton.addTarget(self, action: #selector(cameraButtonHoldDown), for: .touchDown)
        cameraButton.addTarget(self, action: #selector(cameraButtonHoldReleased), for: .touchUpInside)

        setupUI()

        // Do any additional setup after loading the view.
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // End dhCaptureSessionDelegate session
        dhCaptureSessionDelegate?.stopSession()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // dhCaptureSessionDelegate request camera access
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [weak self] granted in
            guard granted != false else {
                debugPrint("Camera access denied", #line)
                return
            }

            DispatchQueue.main.async {
                if self?.dhCaptureSessionDelegate == nil {
                    // video access was enabled so setup video feed
                    #if !targetEnvironment(simulator)
                    // camera preview is not available on simulator
                        self?.dhCaptureSessionDelegate = DHCaptureSession(delegate: self)
                    #endif
                } else {
                    // video feed already available, restart session...
                    self?.dhCaptureSessionDelegate?.startSession()
                }
            }
        }
    }

    // MARK: - Methods

    private func setupUI() {
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        torchButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        rotateCameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)

        cameraButton.setImage(notActiveButtonImage, for: .normal)
    }

    private func initProgressView(inView view: UIView, withDuration duration: TimeInterval) {
        // aspect ratio constant: 1.2
        let centercameraButtonFrame = (view.bounds.size.width - view.bounds.width/1.2)/2
        let circularProgressViewFrame = CGRect(x: centercameraButtonFrame,
                                               y: centercameraButtonFrame,
                                               width: view.bounds.width/1.2,
                                               height: view.bounds.height/1.2)
        let circularProgressView = RMCircularProgressiveView(frame: circularProgressViewFrame)
        circularProgressView.progressAnimation(duration: duration)
        circularProgressView.alpha = 0
        circularProgressView.tag = circularProgressViewTag
        self.cameraButton.addSubview(circularProgressView)
        UIView.animate(withDuration: 0.5) {
            circularProgressView.alpha = 1
        }
    }

    @objc private func cameraButtonHoldDown() {
        // Set session state
        isRecording = true

        // Make sure progress view is removed from superView
        if let viewWithTag = self.cameraButton.viewWithTag(circularProgressViewTag) {
            viewWithTag.removeFromSuperview()
        }

        if canTakeVideo == true {
            // Start progress view animation
            initProgressView(inView: cameraButton, withDuration: takeVideoLength)

            // Start video recording
            dhCaptureSessionDelegate?.startRecording()

            // Start auto stop recording video
            stopRecordingAfter(timeInterval: takeVideoLength)
        }
    }

    @objc private func cameraButtonHoldReleased() {
        // Set session state
        isRecording = false

        if canTakeVideo != true {
            // Take screenshot
            dhCaptureSessionDelegate?.capturePhoto()
            cameraButton.bubble()
        } else {
            // Stop video recording, get video path
            dhCaptureSessionDelegate?.stopRecording()
            dhCaptureSessionDelegate?.capturedVideoPathURL = { [weak self] (videoUrlPath) in
                guard let self = self else { return }
                self.delegate?.didCapture(video: videoUrlPath)
            }
        }
    }

    private func toggleTorch() {
        torchButton.bubble()

        guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = device.isTorchActive ? .off : .on
            let torchImage = !device.isTorchActive ? SystemIcons.torchFill.image : SystemIcons.torch.image
            torchButton.setImage(torchImage, for: .normal)
            device.unlockForConfiguration()
        } catch {
            debugPrint("Torch could not be used", #line)
        }
    }

    private func stopRecordingAfter(timeInterval time: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            if self.isRecording == true {
                self.cameraButtonHoldReleased()
            }
        }
    }

    // MARK: - Actions

    @IBAction func torchButtonPressed(_ sender: Any) {
        toggleTorch()
    }

    @IBAction func rotateCameraPressed(_ sender: Any) {
        dhCaptureSessionDelegate?.swapCamera()
        torchButton.setImage(SystemIcons.torch.image, for: .normal)
        torchButton.isHidden = !torchButton.isHidden
    }

    @IBAction func photoLibraryButtonPressed(_ sender: Any) {
        self.delegate?.didPressPhotoLibraryButton()
    }

    @IBAction func closeButtonPressed(_ sender: Any) {
        self.delegate?.didDismissCameraSession()
    }
}

// MARK: - VideoFeedDelegate

extension CameraSessionViewController: DHCaptureSessionDelegate {

    func processVideoSnapshot(_ image: UIImage?) {
        dhCaptureSessionDelegate?.stopSession()
        guard let imageCaptured = image else {
            assertionFailure()
            return
        }

        self.delegate?.didCapture(image: imageCaptured)
    }

    func videoFeedSetup(with layer: AVCaptureVideoPreviewLayer) {

        // set the layer size
        layer.frame = cameraPreviewView.layer.bounds

        // add to view
        cameraPreviewView.layer.addSublayer(layer)
    }
}
