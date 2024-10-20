//
//  ExportProfile Export.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import Logging
import OrderedCollections
import TimecodeKitCore

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
