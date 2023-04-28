//
//  MarkersExtractor.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import AppKit
import Foundation
import Logging
import OrderedCollections
import TimecodeKit

public final class MarkersExtractor {
    private let logger: Logger
    private let s: Settings
    
    public init(_ settings: Settings, logger: Logger? = nil) {
        self.logger = logger ?? Logger(label: "\(MarkersExtractor.self)")
        s = settings
    }
}

// MARK: - Run

extension MarkersExtractor {
    public func extract() throws {
        try run()
    }
    
    func run() throws {
        let imageFormatEXT = s.imageFormat.rawValue.uppercased()
        
        logger.info("Starting")
        
        logger.info("Using \(s.exportFormat.name) export profile.")
        
        logger.info("Extracting markers from \(s.fcpxml).")
        
        var markers = try extractMarkers()
        
        markers = uniquingMarkerIDs(in: markers)
        
        guard !markers.isEmpty else {
            logger.info("No markers found.")
            // TODO: should we output done file still?
            return
        }
        
        if !EmbeddedResource.validateAll() {
            logger.warning(
                "Could not validate internal resource files. Export may not work correctly."
            )
        }
        
        let projectName = markers[0].parentInfo.projectName
        
        let outputURL = try makeOutputPath(for: projectName)
        
        if s.noMedia {
            logger.info("No media present. Skipping thumbnail generation.")
            logger.info("Generating metadata file(s) into \(outputURL.path.quoted).")
        } else {
            logger.info(
                "Generating metadata file(s) with \(imageFormatEXT) thumbnail images into \(outputURL.path.quoted)."
            )
        }
        
        func callExport<P: ExportProfile>(
            for format: P.Type,
            payload: P.Payload
        ) throws {
            var media: ExportMedia?
            if !s.noMedia {
                let videoPath = try findMedia(name: projectName, paths: s.mediaSearchPaths)
                logger.info("Found project media file \(videoPath.path.quoted).")
                
                let imageQuality = Double(s.imageQuality) / 100
                let imageLabelFontAlpha = Double(s.imageLabelFontOpacity) / 100
                let imageLabels = OrderedSet(s.imageLabels).map { $0 }
                
                let labelProperties = MarkerLabelProperties(
                    fontName: s.imageLabelFont,
                    fontMaxSize: s.imageLabelFontMaxSize,
                    fontColor: NSColor(
                        hexString: s.imageLabelFontColor,
                        alpha: imageLabelFontAlpha
                    ),
                    fontStrokeColor: NSColor(
                        hexString: s.imageLabelFontStrokeColor,
                        alpha: imageLabelFontAlpha
                    ),
                    fontStrokeWidth: s.imageLabelFontStrokeWidth,
                    alignHorizontal: s.imageLabelAlignHorizontal,
                    alignVertical: s.imageLabelAlignVertical
                )
                
                let imageSettings = ExportImageSettings(
                    gifFPS: s.gifFPS,
                    gifSpan: s.gifSpan,
                    format: s.imageFormat,
                    quality: imageQuality,
                    dimensions: calcVideoDimensions(for: videoPath),
                    labelFields: imageLabels,
                    labelCopyright: s.imageLabelCopyright,
                    labelProperties: labelProperties,
                    imageLabelHideNames: s.imageLabelHideNames
                )
                
                media = .init(videoURL: videoPath, imageSettings: imageSettings)
            }
            try P().export(
                markers: markers,
                idMode: s.idNamingMode,
                media: media,
                outputURL: outputURL,
                payload: payload,
                createDoneFile: s.createDoneFile,
                doneFilename: s.doneFilename,
                logger: logger
            )
        }
        
        do {
            switch s.exportFormat {
            case .airtable:
                try callExport(
                    for: AirtableExportProfile.self,
                    payload: .init(projectName: projectName, outputURL: outputURL)
                )
            case .notion:
                try callExport(
                    for: NotionExportProfile.self,
                    payload: .init(projectName: projectName, outputURL: outputURL)
                )
            }
        } catch {
            throw MarkersExtractorError.runtimeError(
                "Failed to export: \(error.localizedDescription)"
            )
        }
        
        logger.info("Done")
    }
}

// MARK: - Extract Markers

extension MarkersExtractor {
    /// Extract markers from `fcpxml` and optionally sort them chronologically by timecode.
    ///
    /// Does not perform any ID uniquing.
    /// To subsequently unique the resulting `[Marker]`, call `uniquingMarkerIDs(in:)`
    internal func extractMarkers(sort: Bool = true) throws -> [Marker] {
        var markers: [Marker]
        
        do {
            markers = try FCPXMLMarkerExtractor(
                fcpxml: s.fcpxml,
                idNamingMode: s.idNamingMode,
                includeOutsideClipBoundaries: s.includeOutsideClipBoundaries,
                excludeRoleType: s.excludeRoleType,
                enableSubframes: s.enableSubframes,
                logger: logger
            ).extractMarkers()
        } catch {
            throw MarkersExtractorError.runtimeError(
                "Failed to parse \(s.fcpxml): \(error.localizedDescription)"
            )
        }
        
        if !isAllUniqueIDNonEmpty(in: markers) {
            throw MarkersExtractorError.runtimeError(
                "Empty marker ID encountered. Markers must have valid non-empty IDs."
            )
        }
        
        let duplicates = findDuplicateIDs(in: markers)
        if !duplicates.isEmpty {
            // duplicate marker IDs isn't be an error condition, we should append filename uniquing
            // string to the ID instead.
            // throw MarkersExtractorError.runtimeError("Duplicate marker IDs found: \(duplicates)")
            logger.info("Duplicate marker IDs found which will be uniqued: \(duplicates)")
        }
        
        if sort {
            markers.sort()
        }
        
        return markers
    }
    
    /// Uniques marker IDs. (Works better if the array is sorted by timecode first.)
    internal func uniquingMarkerIDs(in markers: [Marker]) -> [Marker] {
        var markers = markers
        
        let dupeIndices = Dictionary(
            grouping: markers.indices,
            by: { markers[$0].id(s.idNamingMode) }
        )
        .filter { $1.count > 1 }
        
        for (_, indices) in dupeIndices {
            var counter = 1
            for index in indices {
                markers[index].idSuffix = "-\(counter)"
                counter += 1
            }
        }
        
        return markers
    }
    
    internal func findDuplicateIDs(in markers: [Marker]) -> [String] {
        Dictionary(grouping: markers, by: { $0.id(s.idNamingMode) })
            .filter { $1.count > 1 }
            .compactMap { $0.1.first }
            .map { $0.id(s.idNamingMode) }
            .sorted()
    }
    
    internal func isAllUniqueIDNonEmpty(in markers: [Marker]) -> Bool {
        markers
            .map { $0.id(s.idNamingMode) }
            .allSatisfy { !$0.isEmpty }
    }
}

// MARK: - Output Path

extension MarkersExtractor {
    private func makeOutputPath(for projectName: String) throws -> URL {
        let outputURL = s.outputDir.appendingPathComponent(
            s.exportFolderFormat.folderName(projectName: projectName, profile: s.exportFormat)
        )
        
        do {
            try FileManager.default.mkdirWithParent(outputURL.path, reuseExisting: false)
        } catch {
            throw MarkersExtractorError.runtimeError(
                "Failed to create output dir \(outputURL.path.quoted): \(error.localizedDescription)"
            )
        }
        
        return outputURL
    }
}

// MARK: - Media

extension MarkersExtractor {
    private func findMedia(name: String, paths: [URL]) throws -> URL {
        let mediaFormats = ["mov", "mp4", "m4v", "mxf", "avi", "mts", "m2ts", "3gp"]
        
        let files: [URL] = try paths.reduce(into: []) { base, path in
            do {
                let matches = try matchFiles(at: path, name: name, exts: mediaFormats)
                base.append(contentsOf: matches)
            } catch {
                throw MarkersExtractorError.runtimeError(
                    "Error finding media for \(name.quoted): \(error.localizedDescription)"
                )
            }
        }
        
        if files.isEmpty {
            throw MarkersExtractorError.runtimeError("No media found for \(name.quoted).")
        }
        
        let selection = files[0]
        
        if files.count > 1 {
            logger.info(
                "Found more than one media candidate for \(name.quoted). Using first match: \(selection.path.quoted)"
            )
        }
        
        return selection
    }
    
    private func matchFiles(at path: URL, name: String, exts: [String]) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
            .filter {
                $0.lastPathComponent.starts(with: name)
                    && exts.contains($0.fileExtension)
            }
    }
}

// MARK: - Helpers

extension MarkersExtractor {
    private func calcVideoDimensions(for videoPath: URL) -> CGSize? {
        if s.imageWidth != nil || s.imageHeight != nil {
            return CGSize(width: s.imageWidth ?? 0, height: s.imageHeight ?? 0)
        } else if let imageSizePercent = s.imageSizePercent {
            return calcVideosSizePercent(at: videoPath, for: imageSizePercent)
        }

        return nil
    }

    private func calcVideosSizePercent(at path: URL, for percent: Int) -> CGSize? {
        let asset = AVAsset(url: path)
        let ratio = Double(percent) / 100

        guard let origDimensions = asset.firstVideoTrack?.dimensions else {
            return nil
        }

        return origDimensions * ratio
    }
}
