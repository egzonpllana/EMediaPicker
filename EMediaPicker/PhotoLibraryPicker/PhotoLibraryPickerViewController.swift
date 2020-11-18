//
//  PhotoLibraryPickerViewController.swift
//  EMediaPicker
//
//  Created by Egzon Pllana on 11/18/20.
//  Copyright © 2020 Native Coders. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary

private enum SelectMediaType {
    case photos
    case videos
}

protocol PhotoLibraryPickerDelegate: class {
    func didFinishSelectingAssets(selectedAssets assets: [MediaAsset])
    func didPressCameraButton()
    func didDismissPhotoLibraryPicker()
}

class PhotoLibraryPickerViewController: UIViewController, Storyboardable {

    // MARK: - Storyboardable

    static var storyboardName: String = "PhotoLibraryPicker"

    // MARK: - Outlets

    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var photosVideosHeightConstraint: NSLayoutConstraint!

    // MARK: - Properties


    @IBOutlet weak var photosVideosControl: UISegmentedControl!

    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - Properties

    weak var delegate: PhotoLibraryPickerDelegate?

    let phFetchOptionsCreationDate = "creationDate"
    var photosSelectedCountChanged: ((Int) -> Void)?

    var maximumImagesSelection: Int = 50
    var maximumVideoSelection: Int = 10
    var canPickVideos: Bool = true

    fileprivate var selectedImageAssets: [PHAsset] = []
    fileprivate var selectedVideoAssets: [PHAsset] = []

    private var selectingMediaType: SelectMediaType = .photos {
        didSet {
            collectionView?.reloadData()
        }
    }

    // Lazy Properties
    fileprivate lazy var imagesAssets: [PHAsset] = {
        var assets: [PHAsset] = []
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: phFetchOptionsCreationDate, ascending: false)
        ]
        let result = PHAsset.fetchAssets(with: .image, options: options)
        result.enumerateObjects({ (asset, _, _) in
            assets.append(asset)
        })
        return assets
    }()

    fileprivate lazy var videoAssets: [PHAsset] = {
        var assets: [PHAsset] = []
        let options = PHFetchOptions()
        options.sortDescriptors = [
            NSSortDescriptor(key: phFetchOptionsCreationDate, ascending: false)
        ]

        let result = PHAsset.fetchAssets(with: .video, options: options)
        result.enumerateObjects({ (asset, _, _) in
            assets.append(asset)
        })

        return assets
    }()

    // Selection of Assets
    var currentAssets: [PHAsset] {
        if selectingMediaType == .photos {
            return imagesAssets
        } else if selectingMediaType == .videos {
            return videoAssets
        } else {
            return []
        }
    }

    var selectedAssets: [PHAsset] {
        get {
            if selectingMediaType == .photos {
                return selectedImageAssets
            } else if selectingMediaType == .videos {
                return selectedVideoAssets
            } else {
                return []
            }
        }

        set {
            if selectingMediaType == .photos {
                selectedImageAssets = newValue
            } else if selectingMediaType == .videos {
                selectedVideoAssets = newValue
            }

            let showCameraButton = (newValue.count > 0) ? false : true
            self.cameraButton.isHidden = !showCameraButton
            self.doneButton.isHidden = showCameraButton
        }
    }

    var selectionAssetsLeftCount: Int {
        if selectingMediaType == .photos {
            return maximumImagesSelection - selectedImageAssets.count
        } else if selectingMediaType == .videos {
            return maximumVideoSelection - selectedVideoAssets.count
        } else {
            return 0
        }
    }

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        collectionView.delegate = self
        collectionView.dataSource = self

        // App does not support video picker
        photosVideosHeightConstraint.constant = canPickVideos ? 50.0 : 0.0
        photosVideosControl.isHidden = !canPickVideos

        // Do any additional setup after loading the view.
    }

    // MARK: - Methods

    func getSelectedImages(completion: @escaping (([PHAsset: UIImage]) -> Void)) {
        if selectingMediaType == .photos {
            var assets: [PHAsset: UIImage] = [:]
            selectedAssets.forEach { (asset) in
                getOriginalSizeImageFromAssets(for: asset) { (asset, image) in
                    if let image = image {
                        assets[asset] = image
                        if assets.count == self.selectedAssets.count {
                            completion(assets)
                        }
                    } else {
                        completion([:])
                        return
                    }
                }
            }
        }
    }

    func getSelectedVideos(completion: @escaping (([PHAsset: URL]) -> Void)) {
        if selectingMediaType == .videos {
            var assets: [PHAsset: URL] = [:]
            selectedAssets.forEach { (asset) in
                getVideoURLFromAssets(for: asset) { (asset, assetUrl) in
                    if let assetUrl = assetUrl {
                        assets[asset] = assetUrl
                        if assets.count == self.selectedAssets.count {
                            completion(assets)
                        }
                    } else {
                        completion([:])
                        return
                    }
                }
            }
        }
    }

    // MARK: - Actions

    @IBAction func photosVideosControlChanged(_ sender: Any) {
        switch photosVideosControl.selectedSegmentIndex
            {
            case 0:
                self.selectingMediaType = .photos
            case 1:
                self.selectingMediaType = .videos
            default:
                break
            }
    }


    @IBAction func doneButtonPressed(_ sender: Any) {
        if selectingMediaType == .photos {
            getSelectedImages(completion: { [weak self] (assets) in
                guard let self = self else { return }

                var imageAssets: [MediaAsset] = []
                assets.forEach { (asset, image) in
                    imageAssets.append(MediaAsset(asset: asset, image: image, pathURL: nil, type: .imageFromLibary))
                }

                if imageAssets.count == assets.count {
                    self.delegate?.didFinishSelectingAssets(selectedAssets: imageAssets)
                }
            })
        } else {
            getSelectedVideos(completion: { [weak self] (assets) in
                guard let self = self else { return }

                var videoAssets: [MediaAsset] = []
                assets.forEach { (asset, url) in
                    videoAssets.append(MediaAsset(asset: asset, image: thumbnailFromURL(url: url), pathURL: url, type: .videoFromLibrary))
                }

                if videoAssets.count == assets.count {
                    DispatchQueue.main.async {
                        self.delegate?.didFinishSelectingAssets(selectedAssets: videoAssets)
                    }
                }
            })
        }
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func dismissButtonPressed(_ sender: Any) {
        self.delegate?.didDismissPhotoLibraryPicker()
    }

    @IBAction func cameraButtonPressed(_ sender: Any) {
        self.delegate?.didPressCameraButton()
    }
}

// MARK: - Collection View

extension PhotoLibraryPickerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentAssets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell: RMAssetsPickerCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        let asset = self.currentAssets[indexPath.item]
        let assetSize = CGSize(width: cell.frame.width * 3, height: cell.frame.width * 3)
        cell.asset = asset
        getImageWithSizeFromAssets(for: asset, size: assetSize) { (fetchedAsset, image) in
            if cell.asset == fetchedAsset {
                cell.populateCell(withImage: image)
            }
        }

        cell.isAssetSelected = selectedAssets.contains(asset)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let asset = self.currentAssets[indexPath.item]

        if let index = selectedAssets.firstIndex(of: asset) {
            selectedAssets.remove(at: index)
            collectionView.reloadItems(at: [indexPath])
        } else {
            guard selectionAssetsLeftCount > 0 else { return }

            selectedAssets.append(asset)
            collectionView.reloadItems(at: [indexPath])
        }
    }
}

// MARK: - Request Image

extension PhotoLibraryPickerViewController {
    fileprivate func getImageWithSizeFromAssets(for asset: PHAsset, size: CGSize, completion: ((PHAsset, UIImage?) -> Void)? = nil) {

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact

        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, _ in
            completion?(asset, image)
        }
    }

    func getOriginalSizeImageFromAssets(for asset: PHAsset, completion: @escaping ((PHAsset, UIImage?) -> Void)) {

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact

        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (image, _) in
            completion(asset, image)
        }
    }

    func getVideoURLFromAssets(for asset: PHAsset, completion: @escaping ((PHAsset, URL?) -> Void)) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .fastFormat
        options.version = .original

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avasset, _, _) in
            if let avAsset = avasset as? AVURLAsset {
                completion(asset, avAsset.url)
            } else {
                completion(asset, nil)
            }
        }
    }

    func deleteAssetsWithIdentifier(assetsToDelete assets: [PHAsset], completion: @escaping ((Bool) -> Void)) {
        let identifierAssets = PHAsset.fetchAssets(withLocalIdentifiers: assets.map { $0.localIdentifier }, options: nil)
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(identifierAssets)
            }, completionHandler: { (success, error) in
                debugPrint("Success \(success) - Error \(String(describing: error))")
        })
    }
}
