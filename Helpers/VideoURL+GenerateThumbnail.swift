//
//  VideoURL+GenerateThumbnail.swift
//  EMediaPicker
//
//  Created by Egzon Pllana on 11/18/20.
//  Copyright © 2020 Native Coders. All rights reserved.
//

import UIKit
import Photos

func thumbnailFromURL(url: URL) -> UIImage? {
    do {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        let cgImage = try imageGenerator.copyCGImage(at: .zero,
                                                     actualTime: nil)
        return UIImage(cgImage: cgImage)
    } catch {
        debugPrint(error.localizedDescription)
        return nil
    }
}
