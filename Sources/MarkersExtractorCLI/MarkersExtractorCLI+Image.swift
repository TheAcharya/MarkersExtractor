//
//  MarkersExtractorCLI+Image.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import ArgumentParser
import Foundation
import Logging
import MarkersExtractor
import DAWFileKit

extension MarkersExtractorCLI {
    struct ImageOptions: ParsableArguments {
        @Option(
            help: ArgumentHelp(
                "Marker thumb image format. 'gif' is animated and additional options can be specified with --gif-fps and --gif-span.",
                valueName: caseIterableValueString(for: MarkerImageFormat.self)
            )
        )
        var imageFormat: MarkerImageFormat = MarkersExtractor.Settings.Defaults.imageFormat
        
        @Option(
            help: ArgumentHelp(
                "Image quality percent for JPG.",
                valueName: "\(MarkersExtractor.Settings.Validation.imageQuality)"
            )
        )
        var imageQuality: Int = MarkersExtractor.Settings.Defaults.imageQuality
        
        @Option(help: ArgumentHelp("Limit image width keeping aspect ratio.", valueName: "w"))
        var imageWidth: Int?
        
        @Option(help: ArgumentHelp("Limit image height keeping aspect ratio.", valueName: "h"))
        var imageHeight: Int?
        
        @Option(
            help: ArgumentHelp(
                "Limit image size to % keeping aspect ratio. (default for GIF: \(MarkersExtractor.Settings.Defaults.imageSizePercentGIF))",
                valueName: "\(MarkersExtractor.Settings.Validation.imageSizePercent)"
            )
        )
        var imageSizePercent: Int?
        
        @Option(
            help: ArgumentHelp(
                "GIF frame rate.",
                valueName: "\(MarkersExtractor.Settings.Validation.outputFPS)"
            )
        )
        var gifFPS: Double = MarkersExtractor.Settings.Defaults.gifFPS
        
        @Option(help: ArgumentHelp("GIF capture span around marker.", valueName: "sec"))
        var gifSpan: TimeInterval = MarkersExtractor.Settings.Defaults.gifSpan
    }
}
