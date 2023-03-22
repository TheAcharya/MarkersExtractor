//
//  ExportMedia.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging
import TimecodeKit
import OrderedCollections

// MARK: - Export media information packet

public struct ExportMedia {
    var videoURL: URL
    var imageSettings: ExportImageSettings
}

// MARK: - Export methods when Media is present

extension ExportProfile {
    // TODO: shouldn't take both markers and preparedMarkers
    static func exportThumbnails(
        markers: [Marker],
        preparedMarkers: [Self.PreparedMarker],
        isVideoPresent: Bool,
        isSingleFrame: Bool,
        media: ExportMedia,
        outputURL: URL,
        logger: inout Logger
    ) throws {
        var videoURL: URL = media.videoURL
        let videoPlaceholder: TemporaryMediaFile
        
        if !isVideoPresent {
            logger.info("Media file has no video track, using video placeholder for markers.")
            
            if let markerVideoPlaceholderData = EmbeddedResource.marker_video_placeholder_mov.data {
                videoPlaceholder = try TemporaryMediaFile(withData: markerVideoPlaceholderData)
                if let url = videoPlaceholder.url {
                    videoURL = url
                } else {
                    logger.warning("Could not locate or read video placeholder file.")
                }
            } else {
                logger.warning("Could not locate or read video placeholder file.")
            }
        }
        
        logger.info("Generating \(media.imageSettings.format.rawValue.uppercased()) images for markers.")
        
        let imageLabelText = makeImageLabelText(
            preparedMarkers: preparedMarkers,
            imageLabelFields: media.imageSettings.labelFields,
            imageLabelCopyright: media.imageSettings.labelCopyright,
            includeHeaders: !media.imageSettings.imageLabelHideNames
        )
        
        let timecodes = makeTimecodes(
            markers: markers,
            preparedMarkers: preparedMarkers,
            isVideoPresent: isVideoPresent,
            isSingleFrame: isSingleFrame
        )
        
        switch media.imageSettings.format {
        case let .still(stillImageFormat):
            try writeStillImages(
                timecodes: timecodes,
                video: videoURL,
                outputURL: outputURL,
                imageFormat: stillImageFormat,
                imageJPGQuality: media.imageSettings.quality,
                imageDimensions: media.imageSettings.dimensions,
                imageLabelText: imageLabelText,
                imageLabelProperties: media.imageSettings.labelProperties
            )
        case let .animated(animatedImageFormat):
            try writeAnimatedImages(
                timecodes: timecodes,
                video: videoURL,
                outputURL: outputURL,
                gifFPS: media.imageSettings.gifFPS,
                gifSpan: media.imageSettings.gifSpan,
                gifDimensions: media.imageSettings.dimensions,
                imageFormat: animatedImageFormat,
                imageLabelText: imageLabelText,
                imageLabelProperties: media.imageSettings.labelProperties
            )
        }
    }
    
    private static func makeImageLabelText(
        preparedMarkers: [PreparedMarker],
        imageLabelFields: [ExportField],
        imageLabelCopyright: String?,
        includeHeaders: Bool
    ) -> [String] {
        var imageLabelText: [String] = []
        
        if !imageLabelFields.isEmpty {
            imageLabelText.append(
                contentsOf: makeLabels(
                    headers: imageLabelFields,
                    includeHeaders: includeHeaders,
                    preparedMarkers: preparedMarkers
                )
            )
        }
        
        if let copyrightText = imageLabelCopyright {
            if imageLabelText.isEmpty {
                imageLabelText = preparedMarkers.map { _ in copyrightText }
            } else {
                imageLabelText = imageLabelText.map { "\($0)\n\(copyrightText)" }
            }
        }
        
        return imageLabelText
    }
    
    private static func makeLabels(
        headers: [ExportField],
        includeHeaders: Bool,
        preparedMarkers: [PreparedMarker]
    ) -> [String] {
        preparedMarkers
            .map { manifestFields(for: $0, noMedia: false) }
            .map { markerDict in
                headers
                    .map {
                        (includeHeaders ? "\($0.name): " : "")
                        + "\(markerDict[$0] ?? "")"
                    }
                    .joined(separator: "\n")
            }
    }
    
    /// Returns an ordered dictionary keyed by marker image filename with a value of timecode
    /// position.
    private static func makeTimecodes(
        markers: [Marker],
        preparedMarkers: [PreparedMarker],
        isVideoPresent: Bool,
        isSingleFrame: Bool
    ) -> OrderedDictionary<String, Timecode> {
        let imageFileNames = preparedMarkers.map { $0.imageFileName }
        
        // if no video - grabbing first frame from video placeholder
        let markerTimecodes = markers.map {
            isVideoPresent ? $0.position : .init(at: $0.frameRate())
        }
        
        var markerPairs = zip(imageFileNames, markerTimecodes).map { ($0, $1) }
        
        // if no video and no labels - only one frame needed for all markers
        if isSingleFrame {
            markerPairs = [markerPairs[0]]
        }
        
        return OrderedDictionary(uniqueKeysWithValues: markerPairs)
    }
}
