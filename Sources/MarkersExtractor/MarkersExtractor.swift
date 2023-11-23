//
//  MarkersExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AppKit
import AVFoundation
import DAWFileKit
import Foundation
import Logging
import TimecodeKit

public final class MarkersExtractor: NSObject, ProgressReporting {
    public let logger: Logger
    var s: Settings
    public let progress: Progress
    
    public init(_ settings: Settings, logger: Logger? = nil) {
        self.logger = logger ?? Logger(label: "\(MarkersExtractor.self)")
        s = settings
        progress = Progress()
    }
}

// MARK: - Extract

extension MarkersExtractor {
    /// Run primary batch extract process.
    /// For progress reporting, access the ``progress`` property.
    ///
    /// - Throws: ``MarkersExtractorError``
    public func extract() async throws {
        progress.completedUnitCount = 0
        progress.totalUnitCount = 100
        
        logger.info("Using \(s.exportFormat.name) export profile.")
        logger.info("Extracting markers from \(s.fcpxml)...")
        
        // increments progress by 5%
        var markers = try extractMarkers(
            parentProgress: ParentProgress(progress: progress, unitCount: 5)
        )
        
        progress.completedUnitCount += 5
        
        markers = uniquingMarkerIDs(in: markers)
        
        guard !markers.isEmpty else {
            logger.info("No markers found.")
            // TODO: should we output done file still?
            return
        }
        
        progress.completedUnitCount += 5
        
        if !EmbeddedResource.validateAll() {
            logger.warning(
                "Could not validate internal resource files. Export may not work correctly."
            )
        }
        
        let projectName = markers[0].parentInfo.projectName
        
        let dawFile = try s.fcpxml.dawFile()
        guard let project = dawFile.allProjects(context: MarkersExtractor.elementContext).first
        else {
            throw MarkersExtractorError.extraction(.projectMissing(
                "Could not find a project in the XML file."
            ))
        }
        
        let projectStartTimecode: Timecode = startTimecode(forProject: project)
        
        let outputURL = try makeOutputPath(for: projectName)
        
        let media: ExportMedia?
        if s.noMedia {
            media = nil
            logger.info("No media present. Skipping thumbnail generation.")
            logger.info("Generating metadata file(s) into \(outputURL.path.quoted).")
        } else {
            let exportMedia = try formExportMedia(projectName: projectName)
            media = exportMedia
            logger.info("Found project media file: \(exportMedia.videoURL.path.quoted).")
            logger.info(
                "Generating metadata file(s) with \(s.imageFormat.name) thumbnail images into \(outputURL.path.quoted)."
            )
        }
        
        progress.completedUnitCount += 5
        
        // increments progress by 80%
        try await export(
            projectName: projectName,
            projectStartTimecode: projectStartTimecode,
            media: media,
            markers: markers,
            outputURL: outputURL,
            parentProgress: ParentProgress(progress: progress, unitCount: 80)
        )
        
        logger.info("Done")
    }
}
