//
//  SystemIcons.swift
//  EMediaPicker
//
//  Created by Egzon Pllana on 11/18/20.
//  Copyright © 2020 Native Coders. All rights reserved.
//

import UIKit

enum SystemIcons {
    case calendar
    case calendarFill

    case camera
    case cameraFill

    case flag
    case flagFill

    case arrowCounterClockwiseCircle
    case arrowCounterClockwiseCircleFill

    case checkmarkCircle
    case checkmarkCircleFill

    case torch
    case torchFill

    case circle
    case circleDashedInsetFill
}

extension SystemIcons {
    var image: UIImage? {
        switch self {

        // calendar
        case .calendar:
            return UIImage(systemName: "calendar")
        case .calendarFill:
            return UIImage(systemName: "calendar.circle.fill")

            // camera
        case .camera:
            return UIImage(systemName: "camera")
        case .cameraFill:
            return UIImage(systemName: "camera.fill")

            // flag
        case .flag:
            return UIImage(systemName: "flag")
        case .flagFill:
            return UIImage(systemName: "flag.fill")

            // arrow
        case .arrowCounterClockwiseCircle:
            return UIImage(systemName: "arrow.counterclockwise.circle")
        case .arrowCounterClockwiseCircleFill:
            return UIImage(systemName: "arrow.counterclockwise.circle.fill")

            // checkmark
        case .checkmarkCircle:
            return UIImage(systemName: "checkmark.circle")
        case .checkmarkCircleFill:
            return UIImage(systemName: "checkmark.circle.fill")

            // bolt
        case .torch:
            return UIImage(systemName: "bolt")
        case .torchFill:
            return UIImage(systemName: "bolt.fill")

            // circle

        case .circle:
            return UIImage(systemName: "circle")
        case .circleDashedInsetFill:
            return UIImage(systemName: "circle.dashed.inset.fill")
        }
    }
}
