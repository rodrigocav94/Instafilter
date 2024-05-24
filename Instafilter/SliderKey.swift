//
//  ScaleKey.swift
//  Instafilter
//
//  Created by Rodrigo Cavalcanti on 24/05/24.
//

import Foundation
import CoreImage

enum SliderKey: Int, CaseIterable {
    case kCIInputIntensityKey = 0
    case kCIInputRadiusKey, kCIInputScaleKey
    
    var maxValue: Float {
        switch self {
        case .kCIInputIntensityKey:
            1
        case .kCIInputRadiusKey:
            200
        case .kCIInputScaleKey:
            10
        }
    }
    
    var name: String {
        switch self {
        case .kCIInputIntensityKey:
            "Intensity"
        case .kCIInputRadiusKey:
            "Radius"
        case .kCIInputScaleKey:
            "Scale"
        }
    }
    
    var keyName: String {
        switch self {
        case .kCIInputIntensityKey:
            CoreImage.kCIInputIntensityKey
        case .kCIInputRadiusKey:
            CoreImage.kCIInputRadiusKey
        case .kCIInputScaleKey:
            CoreImage.kCIInputScaleKey
        }
    }
    
    var formalName: String {
        switch self {
        case .kCIInputIntensityKey:
            "kCIInputIntensityKey"
        case .kCIInputRadiusKey:
            "kCIInputRadiusKey"
        case .kCIInputScaleKey:
            "kCIInputScaleKey"
        }
    }
}
