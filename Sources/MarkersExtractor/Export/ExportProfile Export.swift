//
//  ExportProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import TimecodeKit

extension ExportProfile {
    public static func export(
        markers: [Marker],
        idMode: MarkerIDMode,
        media: ExportMedia?,
        outputPath: URL,
        payload: Payload,
        createDoneFile: Bool,
        doneFilename: String
    ) throws {
        let logger = Logger(label: "markersExport")
        
        var isVideoPresent: Bool = false
        var isSingleFrame: Bool? = nil
        var mediaInfo: ExportMarkerMediaInfo? = nil
        
        if let media {
            isVideoPresent = self.isVideoPresent(in: media.videoURL)
            isSingleFrame = !isVideoPresent
                && media.imageSettings.labelFields.isEmpty
                && media.imageSettings.labelCopyright == nil
            mediaInfo = .init(imageFormat: media.imageSettings.format, isSingleFrame: isSingleFrame!)
        }
        
        // prepare markers
        
        let preparedMarkers = prepareMarkers(
            markers: markers,
            idMode: idMode,
            payload: payload,
            mediaInfo: mediaInfo
        )
        
        // icons
        
        logger.info("Exporting marker icons.")
        
        do {
            try exportIcons(from: markers, to: outputPath)
        } catch {
            throw MarkersExtractorError.runtimeError("Failed to write marker icons.")
        }
        
        // thumbnail images
        
        if let media {
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
                isSingleFrame: isSingleFrame ?? true
            )
            
            switch media.imageSettings.format {
            case let .still(stillImageFormat):
                try writeStillImages(
                    timecodes: timecodes,
                    video: videoURL,
                    outputPath: outputPath,
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
                    outputPath: outputPath,
                    gifFPS: media.imageSettings.gifFPS,
                    gifSpan: media.imageSettings.gifSpan,
                    gifDimensions: media.imageSettings.dimensions,
                    imageFormat: animatedImageFormat,
                    imageLabelText: imageLabelText,
                    imageLabelProperties: media.imageSettings.labelProperties
                )
            }
        }
        
        // metadata manifest file
        
        try writeManifest(preparedMarkers, payload: payload)
        
        // done file
        
        if createDoneFile {
            logger.info("Creating \(doneFilename.quoted) done file at \(outputPath.path.quoted).")
            let doneFileData = try doneFileContent(payload: payload)
            try saveDoneFile(at: outputPath, fileName: doneFilename, data: doneFileData)
        }
    }
    
    // MARK: Helpers
    
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
            .map { manifestFields(for: $0) }
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
    
    private static func exportIcons(from markers: [Marker], to outputDir: URL) throws {
        let icons = Set(markers.map { Icon($0.type) })
        
        for icon in icons {
            if icon is EmptyExportIcon { continue }
            let targetURL = outputDir.appendingPathComponent(icon.fileName)
            try icon.data.write(to: targetURL)
        }
    }
    
    private static func saveDoneFile(
        at outputPath: URL,
        fileName: String,
        data: Data
    ) throws {
        let doneFile = outputPath.appendingPathComponent(fileName)
        
        do {
            try data.write(to: doneFile)
        } catch {
            throw MarkersExtractorError.runtimeError(
                "Failed to create done file \(doneFile.path.quoted): \(error.localizedDescription)"
            )
        }
    }
    
    private static func isVideoPresent(in videoPath: URL) -> Bool {
        let asset = AVAsset(url: videoPath)
        
        return asset.firstVideoTrack != nil
    }
}
