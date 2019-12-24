//
//  UIView+Bubble.swift
//  CameraSession
//
//  Created by Egzon Pllana on 12/24/19.
//  Copyright © 2019 Native Coders. All rights reserved.
//

import UIKit

extension UIView {
    func bubble(scale transform: CGFloat = 1.25, with time: Double = 0.05) -> Void {
        UIView.animate(withDuration: time, animations: {
            self.transform = CGAffineTransform(scaleX: transform, y: transform)
            self.layoutIfNeeded()
        }) { (completed) in
            if completed {
                UIView.animate(withDuration: time, animations: {
                    self.transform = CGAffineTransform.identity
                    self.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
}
