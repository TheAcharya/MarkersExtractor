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
        outputURL: URL,
        payload: Payload,
        createDoneFile: Bool,
        doneFilename: String,
        logger: Logger? = nil
    ) throws {
        var logger = logger ?? Logger(label: "\(Self.self)")
        
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
            try exportIcons(from: markers, to: outputURL)
        } catch {
            throw MarkersExtractorError.runtimeError("Failed to write marker icons.")
        }
        
        // thumbnail images
        
        if let media {
            try exportThumbnails(
                markers: markers,
                preparedMarkers: preparedMarkers,
                isVideoPresent: isVideoPresent,
                isSingleFrame: isSingleFrame ?? true,
                media: media,
                outputURL: outputURL,
                logger: &logger
            )
        }
        
        // metadata manifest file
        
        try writeManifest(preparedMarkers, payload: payload, noMedia: media == nil)
        
        // done file
        
        if createDoneFile {
            logger.info("Creating \(doneFilename.quoted) done file at \(outputURL.path.quoted).")
            let doneFileData = try doneFileContent(payload: payload)
            try saveDoneFile(at: outputURL, fileName: doneFilename, data: doneFileData)
        }
    }
    
    // MARK: Helpers
    
    private static func exportIcons(from markers: [Marker], to outputDir: URL) throws {
        let icons = Set(markers.map { Icon($0.type) })
        
        for icon in icons {
            if icon is EmptyExportIcon { continue }
            let targetURL = outputDir.appendingPathComponent(icon.fileName)
            try icon.data.write(to: targetURL)
        }
    }
    
    private static func saveDoneFile(
        at outputURL: URL,
        fileName: String,
        data: Data
    ) throws {
        let doneFile = outputURL.appendingPathComponent(fileName)
        
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

