//
//  MarkersExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import AppKit
import AVFoundation
import Logging
import DAWFileKit
import TimecodeKit

public final class MarkersExtractor: NSObject, ProgressReporting {
    internal let logger: Logger
    internal var s: Settings
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
        progress.totalUnitCount = 5
        
        let imageFormatEXT = s.imageFormat.rawValue.uppercased()
        
        logger.info("Starting")
        logger.info("Using \(s.exportFormat.name) export profile.")
        logger.info("Extracting markers from \(s.fcpxml).")
        
        var markers = try extractMarkers(progressUnitCount: 1) // increments progress by 1
        
        progress.completedUnitCount += 1
        
        markers = uniquingMarkerIDs(in: markers)
        
        guard !markers.isEmpty else {
            logger.info("No markers found.")
            // TODO: should we output done file still?
            return
        }
        
        progress.completedUnitCount += 1
        
        if !EmbeddedResource.validateAll() {
            logger.warning(
                "Could not validate internal resource files. Export may not work correctly."
            )
        }
        
        let projectName = markers[0].parentInfo.projectName
        
        let dawFile = try s.fcpxml.dawFile()
        guard let project = dawFile.projects().first else {
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
            logger.info("Generating metadata file(s) with \(imageFormatEXT) thumbnail images into \(outputURL.path.quoted).")
        }
        
        progress.completedUnitCount += 1
        
        try export(
            projectName: projectName,
            projectStartTimecode: projectStartTimecode,
            media: media,
            markers: markers,
            outputURL: outputURL
        )
        
        progress.completedUnitCount += 1
        
        logger.info("Done")
    }
}
