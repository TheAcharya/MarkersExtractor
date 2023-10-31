//
//  ExportImageSettings.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation

public struct ExportImageSettings {
    public let gifFPS: Double
    public let gifSpan: TimeInterval
    public let format: MarkerImageFormat
    
    /// Quality for compressed image formats (0.0 ... 1.0)
    public let quality: Double
    
    public let dimensions: CGSize?
    public let labelFields: [ExportField]
    public let labelCopyright: String?
    public let labelProperties: MarkerLabelProperties
    public let imageLabelHideNames: Bool
}
