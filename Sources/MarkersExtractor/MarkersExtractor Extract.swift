//
//  MarkersExtractor Extract.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AppKit
import AVFoundation
import DAWFileTools
import Foundation
import Logging
import TimecodeKitCore

extension MarkersExtractor {
    /// Run primary batch extract process.
    /// For progress reporting, access the ``progress`` property.
    ///
    /// - Returns: Export result containing the result file contents as strongly-typed properties.
    /// - Throws: ``MarkersExtractorError``
    public func extract() async throws -> ExportResult {
        progress.completedUnitCount = 0
        progress.totalUnitCount = 100
        
        logger.info("MarkersExtractor \(packageVersion)")
        
        logger.info("Using \(settings.exportFormat.name) export profile.")
        
        logger.info("Parsing XML from \(settings.fcpxml)")
        logger.info("Note that this may take several seconds for complex timelines. Please wait...")
        
        logger.info("Extracting \(settings.markersSource)...")
        
        // increments progress by 5%
        var (markers, context) = try await extractMarkers(
            parentProgress: ParentProgress(progress: progress, unitCount: 5)
        )
        
        progress.completedUnitCount += 5
        
        markers = uniquingMarkerIDs(in: markers)
        
        guard !markers.isEmpty else {
            logger.info("No markers found.")
            // TODO: should we output result file still? nothing gets written to disk if there are no markers so probably not.
            return ExportResult(date: Date(), profile: settings.exportFormat, exportFolder: settings.outputDir)
        }
        
        progress.completedUnitCount += 5
        
        if !EmbeddedResource.validateAll() {
            logger.warning(
                "Could not validate internal resource files. Export may not work correctly."
            )
        }
        
        let outputURL = try makeOutputPath(forTimelineName: context.timelineName)
        
        let media: ExportMedia?
        if settings.noMedia {
            media = nil
            logger.info("Bypassing media file.")
        } else {
            do {
                let exportMedia = try formExportMedia(timelineName: context.timelineName)
                media = exportMedia
                logger.info("Found media file: \(exportMedia.videoURL.path.quoted).")
                
                if settings.exportFormat.concreteType.isMediaCapable {
                    logger.info(
                        "Generating \(settings.imageFormat.name) thumbnail images into \(outputURL.path.quoted)."
                    )
                } else {
                    logger.info(
                        "Export profile does not support thumbnail image generation. No thumbnails will be exported."
                    )
                }
            } catch {
                // not a critical error - if no media is found, let extraction continue without media
                media = nil
                logger.info("\(error.localizedDescription)")
                logger.info("Skipping thumbnail images generation.")
            }
        }
        
        logger.info("Generating metadata file(s) into \(outputURL.path.quoted).")
        
        progress.completedUnitCount += 5
        
        // increments progress by 80%
        let exportResult = try await export(
            timelineName: context.timelineName,
            timelineStartTimecode: context.timelineStartTimecode,
            media: media,
            markers: markers,
            outputURL: outputURL,
            parentProgress: ParentProgress(progress: progress, unitCount: 80)
        )
        
        logger.info("Done")
        
        return exportResult
    }
}
