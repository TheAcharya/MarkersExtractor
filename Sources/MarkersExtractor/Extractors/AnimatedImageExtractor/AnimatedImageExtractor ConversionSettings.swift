//
//  AnimatedImageExtractor BatchResult.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import CoreImage
import TimecodeKitCore

extension AnimatedImageExtractor {
    struct ConversionSettings: Sendable {
        var timecodeRange: ClosedRange<Timecode>?
        let sourceMediaFile: URL
        let outputFile: URL
        var dimensions: CGSize?
        var outputFPS: Double
        let imageFilter: (@Sendable (CGImage) -> CGImage)?
        let imageFormat: MarkerImageFormat.Animated
    }
}
