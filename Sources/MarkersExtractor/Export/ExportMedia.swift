//
//  ExportMedia.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import Logging
import TimecodeKit

// MARK: - Export media information packet

public struct ExportMedia {
    var videoURL: URL
    var imageSettings: ExportImageSettings
}

// MARK: - Export methods when Media is present

extension ExportProfile {
    // TODO: shouldn't take both markers and preparedMarkers
    func exportThumbnails(
        markers: [Marker],
        preparedMarkers: [Self.PreparedMarker],
        isVideoPresent: Bool,
        isSingleFrame: Bool,
        media: ExportMedia,
        outputURL: URL,
        logger: inout Logger,
        progressUnitCount: Int64 = 0
    ) async throws {
        var videoURL: URL = media.videoURL
        let videoPlaceholder: TemporaryMediaFile
        
        if !isVideoPresent {
            logger.info("Media file has no video track, using video placeholder for markers.")
            
            if let markerVideoPlaceholderData = EmbeddedResource.marker_video_placeholder_mov.data {
                videoPlaceholder = try TemporaryMediaFile(withData: markerVideoPlaceholderData)
                videoURL = videoPlaceholder.url
            } else {
                logger.warning("Could not locate or read video placeholder file.")
            }
        }
        
        logger.info(
            "Generating \(media.imageSettings.format.name) images for markers."
        )
        
        let imageDescriptors = try makeImageDescriptors(
            markers: markers,
            preparedMarkers: preparedMarkers,
            imageLabelFields: media.imageSettings.labelFields,
            imageLabelCopyright: media.imageSettings.labelCopyright,
            imageLabelIncludeHeaders: !media.imageSettings.imageLabelHideNames,
            isVideoPresent: isVideoPresent,
            isSingleFrame: isSingleFrame
        )
        
        let writer: ImageWriterProtocol
        switch media.imageSettings.format {
        case let .still(stillImageFormat):
            writer = ImagesWriter(
                descriptors: imageDescriptors,
                videoPath: videoURL,
                outputURL: outputURL,
                imageFormat: stillImageFormat,
                imageJPGQuality: media.imageSettings.quality,
                imageDimensions: media.imageSettings.dimensions,
                imageLabelProperties: media.imageSettings.labelProperties,
                exportProfileProgress: progress,
                progressUnitCount: progressUnitCount
            )
        case let .animated(animatedImageFormat):
            writer = AnimatedImagesWriter(
                descriptors: imageDescriptors,
                videoPath: videoURL,
                outputURL: outputURL,
                gifFPS: media.imageSettings.gifFPS,
                gifSpan: media.imageSettings.gifSpan,
                gifDimensions: media.imageSettings.dimensions,
                imageFormat: animatedImageFormat,
                imageLabelProperties: media.imageSettings.labelProperties,
                exportProfileProgress: progress,
                progressUnitCount: progressUnitCount
            )
        }
        
        try await writer.write()
    }
    
    /// - Returns: An array of marker image descriptors.
    private func makeImageDescriptors(
        markers: [Marker],
        preparedMarkers: [PreparedMarker],
        imageLabelFields: [ExportField],
        imageLabelCopyright: String?,
        imageLabelIncludeHeaders: Bool,
        isVideoPresent: Bool,
        isSingleFrame: Bool
    ) throws -> [ImageDescriptor] {
        // TODO: factor out this validation, we shouldn't need both [Marker] and [PreparedMarker]
        guard markers.count == preparedMarkers.count else {
            throw MarkersExtractorError.extraction(
                .internalInconsistency("Markers array sizes were not equal while attempting to prepare image descriptors.")
            )
        }
        
        let imageFileNames = preparedMarkers.map { $0.imageFileName }
        
        // if no video - grabbing first frame from video placeholder
        let markerTimecodes = markers.map {
            isVideoPresent ? $0.position : .init(.zero, at: $0.frameRate())
        }
        
        let labels = makeImageLabelText(
            preparedMarkers: preparedMarkers,
            imageLabelFields: imageLabelFields,
            imageLabelCopyright: imageLabelCopyright,
            includeHeaders: imageLabelIncludeHeaders
        )
        
        guard markers.count == labels.count else {
            throw MarkersExtractorError.extraction(
                .internalInconsistency("Markers array sizes were not equal while attempting to prepare image descriptors.")
            )
        }
        
        var descriptors = zip(zip(markerTimecodes, imageFileNames), labels)
            .map {
                ImageDescriptor(timecode: $0.0, name: $0.1, label: $1)
            }
        
        // if no video and no labels - only one frame needed for all markers
        if isSingleFrame, let firstDescriptor = descriptors.first {
            descriptors = [firstDescriptor]
        }
        
        return descriptors
    }
    
    /// - Returns: String array, each element corresponding to a marker.
    private func makeImageLabelText(
        preparedMarkers: [PreparedMarker],
        imageLabelFields: [ExportField],
        imageLabelCopyright: String?,
        includeHeaders: Bool
    ) -> [String] {
        var imageLabels: [String] = makeLabels(
            headers: imageLabelFields,
            includeHeaders: includeHeaders,
            preparedMarkers: preparedMarkers
        )
        
        // add copyright
        if let imageLabelCopyright {
            if imageLabels.isEmpty {
                imageLabels = preparedMarkers.map { _ in imageLabelCopyright }
            } else {
                imageLabels = imageLabels.map { "\($0)\n\(imageLabelCopyright)" }
            }
        }
        
        return imageLabels
    }
    
    /// - Returns: String array, each element corresponding to a marker.
    private func makeLabels(
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
}
