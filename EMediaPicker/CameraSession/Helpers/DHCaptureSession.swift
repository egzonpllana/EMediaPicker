//
//  DHCaptureSession.swift
//  EMediaPicker
//
//  Created by Egzon Pllana on 11/18/20.
//  Copyright © 2020 Native Coders. All rights reserved.
//

import UIKit
import AVFoundation

/// Author: Digital Hound
/// https://stackoverflow.com/a/51832599/7987502
///
/// Defines callbacks associated with the VideoFeed class. Notifies delegate of significant events.
protocol DHCaptureSessionDelegate: class {

    /// Callback triggered when the preview layer for this class has been created and configured. Conforming objects should set and maintain a strong reference to this layer otherwise it will be set to nil when the calling function finishes execution.
    ///
    /// - Parameter layer: The video preview layer associated with the active captureSession in the VideoFeed class.
    func videoFeedSetup(with layer: AVCaptureVideoPreviewLayer)

    /// Callback triggered when a snapshot of the video feed has been generated.
    ///
    /// - Parameter image: image captured
    func processVideoSnapshot(_ image: UIImage?)
}

class DHCaptureSession: NSObject {

    // MARK: Variables

    /// The capture session to be used in this class.
    var captureSession = AVCaptureSession()

    /// The preview layer associated with this session. This class has a
    /// weak reference to this layer, the delegate (usually a ViewController
    /// instance) should add this layer as a sublayer to its preview UIView.
    /// The delegate will have the strong reference to this preview layer.
    weak var previewLayer: AVCaptureVideoPreviewLayer?

    /// The output that handles saving the video stream to a file.
    var fileOutput: AVCaptureMovieFileOutput?

    /// A reference to the active video input
    var activeInput: AVCaptureDeviceInput?

    /// Output for capturing frame grabs of video feed
    var cameraOutput = AVCapturePhotoOutput()

    /// Delegate to receive callbacks about significant events triggered by this class.
    weak var delegate: DHCaptureSessionDelegate?

    /// The capture connection associated with the fileOutput.
    /// Set when fileOutput is created.
    var connection: AVCaptureConnection?

    /// Captured video path
    var capturedVideoPathURL: ((URL) -> Void)?

    // MARK: Public accessors

    /// Public initializer. Accepts a delegate to receive callbacks with the preview layer and any snapshot images.
    ///
    /// - Parameter delegate: A reference to an object conforming to DHCaptureSessionDelegate
    /// to receive callbacks for significant events in this class.
    init(delegate: DHCaptureSessionDelegate?) {
        self.delegate = delegate
        super.init()
        setupSession()
    }

    /// Public accessor to begin a capture session.
    public func startSession() {
        guard captureSession.isRunning == false else {
            return
        }

        captureSession.startRunning()
    }

    /// Public accessor to end the current capture session.
    public func stopSession() {

        // validate
        guard captureSession.isRunning else {
            return
        }

        // end file recording if the session ends and we're currently recording a video to file
        if let isRecording = fileOutput?.isRecording, isRecording {
            stopRecording()
        }

        captureSession.stopRunning()

        print("⚠️ - Camera session stopped. Waiting for deinitialization..")
    }

    /// Public accessor to begin file recording.
    public func startRecording() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }

        guard fileOutput?.isRecording == false else {
            stopRecording()
            return
        }

        configureVideoOrientation()
        disableSmoothAutoFocus()

        guard let url = tempURL() else {
            print("Unable to start file recording, temp url generation failed.")
            return
        }

        fileOutput?.startRecording(to: url, recordingDelegate: self)
    }

    /// Public accessor to end file recording.
    public func stopRecording() {
        guard fileOutput?.isRecording == true else {
            return
        }

        fileOutput?.stopRecording()
    }

    /// Swap camera and reconfigures camera session with new input
    /// * This function "swapCamera" can be improved later. *
    public func swapCamera() {

        /// Get current input
        guard let input = captureSession.inputs[0] as? AVCaptureDeviceInput else { return }

        /// Begin new session configuration and defer commit
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        /// Create new capture device
        var newDevice: AVCaptureDevice?
        if input.device.position == .back {
            newDevice = captureDevice(with: .front)
        } else {
            newDevice = captureDevice(with: .back)
        }

        /// Create new capture input
        var deviceInput: AVCaptureDeviceInput!
        do {
            deviceInput = try AVCaptureDeviceInput(device: newDevice!)
        } catch let error {
            print(error.localizedDescription)
            return
        }

        /// Swap capture device inputs
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                captureSession.removeInput(input)
            }
            captureSession.addInput(deviceInput)
        }
    }

    /// Create new capture device with requested position
    fileprivate func captureDevice(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {

        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInMicrophone, .builtInDualCamera, .builtInTelephotoCamera ],
                                                       mediaType: AVMediaType.video,
                                                       position: .unspecified).devices

        for device in devices where device.position == position {
                return device
            }
        return nil
    }

    /// Public accessor to trigger snapshot capture of video stream.
    public func capturePhoto() {

        // create settings object
        let settings = AVCapturePhotoSettings()

        // verify that we have a pixel format type available
        guard let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first else {
            print("Unable to configure photo capture settings, 'availablePreviewPhotoPixelFormatTypes' has no available options.")
            return
        }

        let screensize = UIScreen.main.bounds.size

        // setup format configuration dictionary
        let previewFormat: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
            kCVPixelBufferWidthKey as String: screensize.width,
            kCVPixelBufferHeightKey as String: screensize.height
        ]
        settings.previewPhotoFormat = previewFormat

        // trigger photo capture
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: Setup functions

    /// Handles configuration and setup of the session, inputs, video preview layer and outputs.
    /// If all are setup and configured it starts the session.
    internal func setupSession() {

        captureSession.sessionPreset = AVCaptureSession.Preset.high
        guard setupInputs() else {
            return
        }

        setupOutputs()
        setupVideoLayer()
        startSession()
    }

    /// Sets up capture inputs for this session.
    ///
    /// - Returns: Returns true if inputs are successfully setup, else false.
    internal func setupInputs() -> Bool {

        // only need access to this functionality within this function, so declare as sub-function
        func addInput(input: AVCaptureInput) {
            guard captureSession.canAddInput(input) else {
                return
            }

            captureSession.addInput(input)
        }

        do {
            if let camera = AVCaptureDevice.default(for: AVMediaType.video) {
                let input = try AVCaptureDeviceInput(device: camera)
                addInput(input: input)
                activeInput = input
            }

            // Setup Microphone
            if let microphone = AVCaptureDevice.default(for: AVMediaType.audio) {
                let micInput = try AVCaptureDeviceInput(device: microphone)
                addInput(input: micInput)
            }

            return true
        } catch {
            print("⚠️ Error setting device video input: \(error)")
            return false
        }
    }

    internal func setupOutputs() {

        // only need access to this functionality within this function, so declare as sub-function
        func addOutput(output: AVCaptureOutput) {
            if captureSession.canAddOutput(output) {
                captureSession.addOutput(output)
            }
        }

        // file output
        self.fileOutput = AVCaptureMovieFileOutput()
        captureSession.addOutput(fileOutput!)

        if let connection = fileOutput!.connection(with: .video), connection.isVideoStabilizationSupported {
            connection.preferredVideoStabilizationMode = .off
            self.connection = connection
        }

        cameraOutput.isHighResolutionCaptureEnabled = true
        captureSession.addOutput(cameraOutput)

    }

    internal func setupVideoLayer() {
        let layer =  AVCaptureVideoPreviewLayer(session: captureSession)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        delegate?.videoFeedSetup(with: layer)
        previewLayer = layer
    }

    // MARK: Helper functions

    /// Creates a url in the temporary directory for file recording.
    ///
    /// - Returns: A file url if successful, else nil.
    internal func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString

        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }

        return nil
    }

    /// Disables smooth autofocus functionality on the active device, if the active device is set and 'isSmoothAutoFocusSupported' is supported for the currently set active device.
    internal func disableSmoothAutoFocus() {

        guard let device = activeInput?.device, device.isSmoothAutoFocusSupported else {
            return
        }

        do {
            try device.lockForConfiguration()
            device.isSmoothAutoFocusEnabled = false
            device.unlockForConfiguration()
        } catch {
            print("⚠️ Error disabling smooth autofocus: \(error)")
        }

    }

    /// Sets the current AVCaptureVideoOrientation on the currently active connection if it's supported.
    internal func configureVideoOrientation() {

        guard let connection = connection, connection.isVideoOrientationSupported,
            let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation,
            let currentOrientation = AVCaptureVideoOrientation(rawValue: interfaceOrientation.rawValue) else {
                return
        }

        connection.videoOrientation = currentOrientation
    }

    deinit {
        print("✅ DHCaptureSession controller de init")
    }
}

// MARK: AVCapturePhotoCaptureDelegate
extension DHCaptureSession: AVCapturePhotoCaptureDelegate {

    // iOS 11+ processing
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil, let outputData = photo.fileDataRepresentation() else {
            print("Photo Error: \(String(describing: error))")
            return
        }

        print("captured photo...")
        loadImage(data: outputData)
    }

    // iOS < 11 processing
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?,
                     previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                     resolvedSettings: AVCaptureResolvedPhotoSettings,
                     bracketSettings: AVCaptureBracketedStillImageSettings?,
                     error: Error?) {

        if #available(iOS 11.0, *) {
            // use iOS 11-only feature
            // nothing to do here as iOS 11 uses the callback above
        } else {
            guard error == nil else {
                print("Photo Error: \(String(describing: error))")
                return
            }

            guard let sampleBuffer = photoSampleBuffer,
                let previewBuffer = previewPhotoSampleBuffer,
                let outputData =  AVCapturePhotoOutput
                    .jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) else {
                        print("Image creation from sample buffer/preview buffer failed.")
                        return
            }

            print("captured photo...")
            loadImage(data: outputData)
        }
    }

    /// Creates a UIImage from Data object received from AVCapturePhotoOutput. delegate callback and sends to the DHCaptureSessionDelegate for handling.
    /// - Parameter data: Image data.
    internal func loadImage(data: Data) {
        guard let dataProvider = CGDataProvider(data: data as CFData),
            let cgImageRef: CGImage = CGImage(jpegDataProviderSource: dataProvider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else {
            return
        }
        let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImage.Orientation.right)
        delegate?.processVideoSnapshot(image)
    }
}

extension DHCaptureSession: AVCaptureFileOutputRecordingDelegate {

    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Video recording started: \(fileURL.absoluteString)")
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        guard error == nil else {
            print("⚠️ Error recording movie: \(String(describing: error))")
            return
        }

        UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
        self.capturedVideoPathURL?(outputFileURL)
    }
}
