//
//  ExportProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import SwiftTimecodeCore

extension ExportProfile {
    public func export(
        markers: [Marker],
        idMode: MarkerIDMode,
        media: ExportMedia?,
        tcStringFormat: Timecode.StringFormat,
        useChapterMarkerPosterOffset: Bool,
        outputURL: URL,
        payload: Payload,
        resultFilePath: URL?,
        logger: Logger? = nil,
        parentProgress: ParentProgress? = nil
    ) async throws -> ExportResult {
        var logger = logger ?? Logger(label: "\(Self.self)")
        
        // export profile ProgressReporting
        progress.completedUnitCount = 0
        progress.totalUnitCount = Self.defaultProgressTotalUnitCount
        
        // attach local progress to parent
        parentProgress?.addChild(progress)
        
        // gather media info
        
        let (isVideoPresent, isSingleFrame, mediaInfo) = gatherMediaInfo(media: media)
        
        // prepare markers
        
        let preparedMarkers = prepareMarkers(
            markers: markers,
            idMode: idMode,
            tcStringFormat: tcStringFormat, 
            useChapterMarkerPosterOffset: useChapterMarkerPosterOffset,
            payload: payload,
            mediaInfo: mediaInfo
        )
        
        // icons
        
        logger.info("Exporting marker icons...")
        
        try writeIcons(from: markers, to: outputURL)
        
        progress.completedUnitCount += 5
        
        // thumbnail images
        
        let thumbnailsProgressUnitCount: Int64 = 90
        if Self.isMediaCapable, let media {
            try await exportThumbnails(
                markers: markers,
                preparedMarkers: preparedMarkers,
                isVideoPresent: isVideoPresent,
                isSingleFrame: isSingleFrame,
                media: media,
                outputFolder: outputURL,
                logger: &logger,
                parentProgress: ParentProgress(
                    progress: progress,
                    unitCount: thumbnailsProgressUnitCount
                )
            )
        } else {
            progress.completedUnitCount += thumbnailsProgressUnitCount
        }
        
        // metadata manifest file(s)
        
        try writeManifests(preparedMarkers, payload: payload, noMedia: media == nil)
        
        // result file
        let exportResult = try generateResult(date: Date(), payload: payload, outputURL: outputURL)
        
        if let resultFilePath {
            logger.info("Creating result file \(resultFilePath.path.quoted).")
            let data = try exportResult.jsonData()
            try writeResultFile(to: resultFilePath, data: data)
        }
        
        progress.completedUnitCount += 5
        
        return exportResult
    }
}

// MARK: - Export When Media is Present

extension ExportProfile {
    // TODO: shouldn't take both markers and preparedMarkers
    func exportThumbnails(
        markers: [Marker],
        preparedMarkers: [Self.PreparedMarker],
        isVideoPresent: Bool,
        isSingleFrame: Bool,
        media: ExportMedia,
        outputFolder: URL,
        logger: inout Logger,
        parentProgress: ParentProgress?
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
            "Generating \(media.imageSettings.format.name) images for markers..."
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
                sourceMediaFile: videoURL,
                outputFolder: outputFolder,
                imageFormat: stillImageFormat,
                imageJPGQuality: media.imageSettings.quality,
                imageDimensions: media.imageSettings.dimensions,
                imageLabelProperties: media.imageSettings.labelProperties
            )
        case let .animated(animatedImageFormat):
            writer = AnimatedImagesWriter(
                descriptors: imageDescriptors,
                sourceMediaFile: videoURL,
                outputFolder: outputFolder,
                gifFPS: media.imageSettings.gifFPS,
                gifSpan: media.imageSettings.gifSpan,
                gifDimensions: media.imageSettings.dimensions,
                imageFormat: animatedImageFormat,
                imageLabelProperties: media.imageSettings.labelProperties
            )
        }
        
        // attach local progress to parent
        parentProgress?.addChild(writer.progress)
        
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
                .internalInconsistency(
                    "Markers array sizes were not equal while attempting to prepare image descriptors."
                )
            )
        }
        
        let imageFileNames = preparedMarkers.map { $0.imageFileName }
        
        // if no video - grabbing first frame from video placeholder using zero timecode
        let offsets: [Timecode] = zip(markers, preparedMarkers)
            .map { marker, preparedMarker in
                if isVideoPresent {
                    let timelineStart = marker.parentInfo.timelineStartTime
                    let offset = preparedMarker.imageTimecode - timelineStart
                    return offset
                } else {
                    return Timecode(
                        .zero,
                        at: marker.frameRate(),
                        base: marker.subFramesBase(),
                        limit: marker.upperLimit()
                    )
                }
            }
        
        let labels = makeImageLabelText(
            preparedMarkers: preparedMarkers,
            imageLabelFields: imageLabelFields,
            imageLabelCopyright: imageLabelCopyright,
            includeHeaders: imageLabelIncludeHeaders
        )
        
        guard [
            markers.count,
            preparedMarkers.count,
            imageFileNames.count,
            offsets.count,
            labels.count
        ]
            .allElementsAreEqual
        else {
            throw MarkersExtractorError.extraction(
                .internalInconsistency(
                    "Markers array sizes were not equal while attempting to prepare image descriptors."
                )
            )
        }
        
        // stitch everything together
        var descriptors = (0 ..< markers.count)
            .map { index in
                ImageDescriptor(
                    absoluteTimecode: markers[index].position,
                    offsetFromVideoStart: offsets[position: index],
                    filename: imageFileNames[position: index],
                    label: labels[position: index]
                )
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
        let markersFields: [OrderedDictionary<ExportField, String>] = preparedMarkers
            .map {
                var fields = tableManifestFields(for: $0, noMedia: false)
                
                // truncate Clip Keywords field, which can sometimes be extremely long
                if let kw = fields[.clipKeywords] {
                    fields[.clipKeywords] = String(kw.prefix(100))
                }
                
                return fields
            }
        
        let markersLabels: [String] = markersFields
            .map { markerDict in
                headers
                    .map {
                        (includeHeaders ? "\($0.name): " : "")
                        + "\(markerDict[$0] ?? "")"
                    }
                    .joined(separator: "\n")
            }
        
        return markersLabels
    }
}

// MARK: - Helpers

extension ExportProfile {
    private func gatherMediaInfo(
        media: ExportMedia?
    ) -> (isVideoPresent: Bool, isSingleFrame: Bool, mediaInfo: ExportMarkerMediaInfo?) {
        guard let media else {
            return (isVideoPresent: false, isSingleFrame: true, mediaInfo: nil)
        }
        
        let isVideoPresent = isVideoPresent(in: media.videoURL)
        let isSingleFrame = !isVideoPresent
            && media.imageSettings.labelFields.isEmpty
            && media.imageSettings.labelCopyright == nil
        let mediaInfo = ExportMarkerMediaInfo(
            imageFormat: media.imageSettings.format,
            isSingleFrame: isSingleFrame
        )
        
        return (isVideoPresent: isVideoPresent, isSingleFrame: isSingleFrame, mediaInfo: mediaInfo)
    }
    
    private func writeIcons(from markers: [Marker], to outputDir: URL) throws {
        let icons = Set(markers.map { Icon($0.type) })
        
        for icon in icons {
            if icon is EmptyExportIcon { continue }
            let targetURL = outputDir.appendingPathComponent(icon.fileName)
            do {
                try icon.data.write(to: targetURL)
            } catch {
                throw MarkersExtractorError.extraction(.fileWrite(error.localizedDescription))
            }
        }
    }
    
    private func generateResult(date: Date, payload: Payload, outputURL: URL) throws -> ExportResult {
        // add baseline data that applies to all profiles
        var exportResult = ExportResult(
            date: date,
            profile: Self.profile,
            exportFolder: outputURL
        )
        
        // add profile-specific data
        let profileResult = try resultFileContent(payload: payload)
        exportResult.update(with: profileResult)
        
        return exportResult
    }
    
    private func writeResultFile(
        to outputURL: URL,
        data: Data
    ) throws {
        do {
            try data.write(to: outputURL)
        } catch {
            throw MarkersExtractorError.extraction(.fileWrite(
                "Failed to create result file \(outputURL.path.quoted): \(error.localizedDescription)"
            ))
        }
    }
    
    private func isVideoPresent(in videoPath: URL) -> Bool {
        let asset = AVAsset(url: videoPath)
        return asset.firstVideoTrack != nil
    }
}
