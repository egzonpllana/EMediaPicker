//
//  OnTouchRecordViewController.swift
//  CameraSession
//
//  Created by Egzon Pllana on 12/24/19.
//  Copyright © 2019 Native Coders. All rights reserved.
//

import UIKit
import AVFoundation

let circularProgressViewTag = 100

class OnTouchRecordViewController: UIViewController, Storyboardable {

    // MARK: - Outlets

    @IBOutlet weak var torchButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var rotateCameraButton: UIButton!
    @IBOutlet weak var cameraPreviewView: UIView!

    // MARK: - Properties

    /// Storyboardable
    static var storyboardName: String = "Main"

    var isTakingVideo: Bool = true {
        didSet {
            setupUI()
        }
    }

    var takeVideoLength: TimeInterval = 10

    var dhCaptureSessionDelegate: DHCaptureSession?
    var videoPathURL: URL?

    var notActiveButtonImage: UIImage?
    var activeButtonImage: UIImage?

    var captureSessionState: Bool = false {
        didSet {
            let cameraButtonStateImage = captureSessionState ? activeButtonImage : notActiveButtonImage
            cameraButton.setImage(cameraButtonStateImage, for: .normal)

            torchButton.isEnabled = !captureSessionState
            rotateCameraButton.isEnabled = !captureSessionState
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
                // TODO: show UI stating camera cannot be used, update in settings app...
                print("Camera access denied", #line)
                return
            }

            DispatchQueue.main.async {
                if self?.dhCaptureSessionDelegate == nil {
                    // video access was enabled so setup video feed
                    self?.dhCaptureSessionDelegate = DHCaptureSession(delegate: self)
                } else {
                    // video feed already available, restart session...
                    self?.dhCaptureSessionDelegate?.startSession()
                }
            }
        }
    }

    // MARK: - Functions

    private func setupUI() {
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        torchButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        rotateCameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)

        notActiveButtonImage = isTakingVideo ? #imageLiteral(resourceName: "video_icon") : #imageLiteral(resourceName: "camera_icon")
        activeButtonImage = isTakingVideo ? #imageLiteral(resourceName: "video_icon_active") : #imageLiteral(resourceName: "camera_icon_active")

        cameraButton.setImage(notActiveButtonImage, for: .normal)
    }

    private func initProgressView(inView view: UIView, withDuration duration: TimeInterval) {
        // aspect ratio constant: 1.2
        let centercameraButtonFrame = (view.bounds.size.width - view.bounds.width/1.2)/2
        let circularProgressViewFrame = CGRect(x: centercameraButtonFrame,
                                               y: centercameraButtonFrame,
                                               width: view.bounds.width/1.2,
                                               height: view.bounds.height/1.2)
        let circularProgressView = CircularProgressView(frame: circularProgressViewFrame)
        circularProgressView.progressAnimation(duration: duration)
        circularProgressView.alpha = 0
        circularProgressView.tag = circularProgressViewTag
        self.cameraButton.addSubview(circularProgressView)
        UIView.animate(withDuration: 0.5) {
            circularProgressView.alpha = 1
        }
    }

    @objc private func cameraButtonHoldDown() {
        /// set session state
        captureSessionState = true

        /// make sure progress view is removed from superView
        if let viewWithTag = self.cameraButton.viewWithTag(circularProgressViewTag) {
            viewWithTag.removeFromSuperview()
        }

        if isTakingVideo == true {
            /// start progress view animation
            initProgressView(inView: cameraButton, withDuration: takeVideoLength)

            /// start video recording
            dhCaptureSessionDelegate?.startRecording()
        }
    }

    @objc private func cameraButtonHoldReleased() {
        /// set session state
        captureSessionState = false

        if isTakingVideo != true {
            /// take screenshot
            dhCaptureSessionDelegate?.capturePhoto()
            cameraButton.bubble()
        } else {
            /// stop video recording, get video path
            dhCaptureSessionDelegate?.stopRecording()
            dhCaptureSessionDelegate?.capturedVideoPathURL = { [weak self] (videoUrlPath) in
                guard let self = self else { return }
                self.videoPathURL = videoUrlPath
                print("Saved video path: ", videoUrlPath, #line)
            }

            /// animate view to dismiss it
            if let viewWithTag = self.cameraButton.viewWithTag(circularProgressViewTag) {
                UIView.animate(withDuration: 0.25, delay: 0.0, options: UIView.AnimationOptions.curveLinear ,animations: {
                    viewWithTag.alpha = 0
                }, completion: { _ in
                    viewWithTag.removeFromSuperview()
                })
            }
        }
    }

    private func toggleTorch() {
        torchButton.bubble()

        guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = device.isTorchActive ? .off : .on
            let torchImage = !device.isTorchActive ? #imageLiteral(resourceName: "flash_icon_active") : #imageLiteral(resourceName: "flash_icon")
            torchButton.setImage(torchImage, for: .normal)
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used", #line)
        }
    }

    // MARK: - Actions

    @IBAction func torchButtonPressed(_ sender: Any) {
        toggleTorch()
    }

    @IBAction func rotateCameraPressed(_ sender: Any) {
        dhCaptureSessionDelegate?.swapCamera()
        torchButton.isEnabled = !torchButton.isEnabled
    }
}

extension OnTouchRecordViewController: DHCaptureSessionDelegate {
    // MARK: - VideoFeedDelegate

    func processVideoSnapshot(_ image: UIImage?) {
        //self.capturedImagePreview.image = image
    }

    func videoFeedSetup(with layer: AVCaptureVideoPreviewLayer) {

        // set the layer size
        layer.frame = cameraPreviewView.layer.bounds

        // add to view
        cameraPreviewView.layer.addSublayer(layer)
    }
}
