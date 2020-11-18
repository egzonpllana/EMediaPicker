//
//  RMAssetsPickerCollectionViewCell.swift
//  EMediaPicker
//
//  Created by Egzon Pllana on 11/18/20.
//  Copyright © 2020 Native Coders. All rights reserved.
//

import UIKit
import Photos

class RMAssetsPickerCollectionViewCell: UICollectionViewCell {

    @IBOutlet private weak var assetImageView: UIImageView!
    @IBOutlet weak var isSelectedIndicatorImageView: UIImageView!

    static let reuseIdentifier = "AssetsPickerCell"

    var asset: PHAsset!
    var isAssetSelected: Bool? {
        didSet {
            guard let selected = isAssetSelected else { return }
            isSelectedIndicatorImageView.image = selected ? SystemIcons.circleDashedInsetFill.image : SystemIcons.circle.image
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
