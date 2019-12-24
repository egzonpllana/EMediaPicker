//
//  AssetsPickerCollectionViewCell.swift
//  CameraSession
//
//  Created by Egzon Pllana on 12/24/19.
//  Copyright © 2019 Native Coders. All rights reserved.
//

import UIKit
import Photos

class AssetsPickerCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var assetImageView: UIImageView!
    @IBOutlet weak var selectedImageView: UIView!

    static let reuseIdentifier = "AssetsPickerCell"

    var asset: PHAsset!
    var isAssetSelected: Bool? {
        didSet {
            guard let selected = isAssetSelected else { return }
            selectedImageView.isHidden = !selected
        }
    }

    func populateCell(withImage image: UIImage?) {
        self.assetImageView.image = image
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        assetImageView.layer.cornerRadius = 6
        assetImageView.layer.masksToBounds = true
        assetImageView.clipsToBounds = true
    }
}
