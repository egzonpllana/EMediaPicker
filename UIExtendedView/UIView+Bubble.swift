//
//  UIView+Bubble.swift
//  EMediaPicker
//
//  Created by Egzon Pllana on 11/18/20.
//  Copyright © 2020 Native Coders. All rights reserved.
//

import UIKit

extension UIView {
    func bubble(scale transform: CGFloat = 1.25, with time: Double = 0.05) {
        UIView.animate(withDuration: time, animations: {
            self.transform = CGAffineTransform(scaleX: transform, y: transform)
            self.layoutIfNeeded()

            // swiftlint:disable multiple_closures_with_trailing_closure
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
