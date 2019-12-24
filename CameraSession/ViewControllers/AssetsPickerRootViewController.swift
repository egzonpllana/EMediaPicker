//
//  AssetsPickerRootViewController.swift
//  CameraSession
//
//  Created by Egzon Pllana on 12/24/19.
//  Copyright © 2019 Native Coders. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary

enum SelectMediaType {
    case images
    case videos
}

class AssetsPickerRootViewController: UIViewController, Storyboardable {

    // MARK: - Properties

    @IBOutlet weak var photosButton: UIButton!
    @IBOutlet weak var videosButton: UIButton!

    @IBOutlet weak var collectionView: UICollectionView!

    // Variables

    /// Storyboardable
    static var storyboardName: String = "Main"

    var maximumImagesSelection: Int = 10
    var maximumVideoSelection: Int = 1

    fileprivate var selectedImageAssets: [PHAsset] = []
    fileprivate var selectedVideoAssets: [PHAsset] = []

    var selectMediaType: SelectMediaType = .images {
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
        result.enumerateObjects({ (asset, index, _) in
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
        result.enumerateObjects({ (asset, index, _) in
            assets.append(asset)
        })

        return assets
    }()

    // Selection of Assets
    var currentAssets: [PHAsset] {
        if selectMediaType == .images {
            return imagesAssets
        } else if selectMediaType == .videos {
            return videoAssets
        } else {
            return []
        }
    }

    var selectedAssets: [PHAsset] {
        get {
            if selectMediaType == .images {
                return selectedImageAssets
            } else if selectMediaType == .videos {
                return selectedVideoAssets
            } else {
                return []
            }
        }

        set {
            if selectMediaType == .images {
                selectedImageAssets = newValue
            } else if selectMediaType == .videos {
                selectedVideoAssets = newValue
            }
        }
    }

    var selectionAssetsLeftCount: Int {
        if selectMediaType == .images {
            return maximumImagesSelection - selectedImageAssets.count
        } else if selectMediaType == .videos {
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

        /// photos is first screen to be presented
        photosButton.isSelected = true

        // Do any additional setup after loading the view.
    }

    // MARK: - Actions

    @IBAction func photosButtonPressed(_ sender: Any) {
        self.selectMediaType = .images
        photosButton.isSelected = true
        videosButton.isSelected = false
    }

    @IBAction func videosButtonPressed(_ sender: Any) {
        self.selectMediaType = .videos
        photosButton.isSelected = false
        videosButton.isSelected = true
    }
}

// MARK: - Collection View

extension AssetsPickerRootViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentAssets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AssetsPickerCollectionViewCell.reuseIdentifier, for: indexPath) as? AssetsPickerCollectionViewCell else {
            return UICollectionViewCell()
        }

        let asset = self.currentAssets[indexPath.item]
        let assetSize = CGSize(width: cell.frame.width * 3, height: cell.frame.width * 3)
        cell.asset = asset
        requestImage(for: asset, size: assetSize) { (fetchedAsset, image) in
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

//MARK:- Request Image

extension AssetsPickerRootViewController {
    fileprivate func requestImage(for asset: PHAsset, size: CGSize, completion: ((PHAsset, UIImage?) -> Void)? = nil) {

        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact

        PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { image, info in
            completion?(asset, image)
        }
    }
}
