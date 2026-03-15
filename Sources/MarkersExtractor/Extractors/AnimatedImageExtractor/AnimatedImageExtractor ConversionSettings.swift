//
//  AnimatedImageExtractor ConversionSettings.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import CoreImage
import Foundation
import SwiftTimecodeCore

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
