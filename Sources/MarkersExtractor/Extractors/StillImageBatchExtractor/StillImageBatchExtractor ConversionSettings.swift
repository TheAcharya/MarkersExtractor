//
//  StillImageBatchExtractor ConversionSettings.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import CoreImage

extension StillImageBatchExtractor {
    struct ConversionSettings: Sendable {
        let descriptors: [ImageDescriptor]
        let sourceMediaFile: URL
        let outputFolder: URL
        let frameFormat: MarkerImageFormat.Still
        
        /// JPG quality: percentage as a unit interval between `0.0 ... 1.0`
        let jpgQuality: Double?
        
        let dimensions: CGSize?
        let imageFilter: (@Sendable (_ image: CGImage, _ label: String?) async -> CGImage)?
    }
}
