//
//  MediaHelper.swift
//  CameraSession
//
//  Created by Egzon Pllana on 12/24/19.
//  Copyright © 2019 Native Coders. All rights reserved.
//

import UIKit
import Photos
import AssetsLibrary

struct MediaHelper {
    static func getImage(for asset: PHAsset, completion: @escaping ((PHAsset, UIImage?) -> Void)) {

        let options = PHImageRequestOptions()
        options.resizeMode = .exact
        options.deliveryMode = .highQualityFormat

        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options) { (image, info) in
            completion(asset, image)
        }
    }
    static func getVideo(for asset: PHAsset, completion: @escaping ((PHAsset, URL?) -> Void)) {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .fastFormat
        options.version = .original

        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avasset, avmix, info) in
            if let avAsset = avasset as? AVURLAsset {
                completion(asset, avAsset.url)
            } else {
                completion(asset, nil)
            }
        }
    }
}
