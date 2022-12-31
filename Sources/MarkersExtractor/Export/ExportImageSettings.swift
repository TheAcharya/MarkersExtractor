//
//  ExportImageSettings.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation

public struct ExportImageSettings<Field> {
    public let gifFPS: Double
    public let gifSpan: TimeInterval
    public let format: MarkerImageFormat
    public let quality: Double
    public let dimensions: CGSize?
    public let labelFields: [Field]
    public let labelCopyright: String?
    public let labelProperties: MarkerLabelProperties
    public let imageLabelHideNames: Bool
}
