//
//  MediaAssetModel.swift
//  EMediaPicker
//
//  Created by Egzon Pllana on 11/18/20.
//  Copyright © 2020 Native Coders. All rights reserved.
//

import UIKit
import Photos

enum MediaAssetType {
    case videoFromLibrary
    case videoFromCamera
    case imageFromCamera
    case imageFromLibary
}

struct MediaAsset {
    let asset: PHAsset?
    let image: UIImage?
    let pathURL: URL?

    let type: MediaAssetType
}

// Not in use
extension MediaAsset {
    var asMediaModel: MediaModel? {
        if let image = image, let data = image.jpegData(compressionQuality: 0.2) {
            return MediaModel(data: data, type: MediaModelOptions.image.rawValue)
        } else {
            return nil
        }
    }
}
