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
    private let logger = Logger(label: "\(MarkersExtractor.self)")
    private let s: Settings
    
    init(_ settings: Settings) {
        s = settings
    }
}

// MARK: - Run

extension MarkersExtractor {
    public static func extract(_ settings: Settings) throws {
        try self.init(settings).run()
    }
    
    func run() throws {
        let imageQuality = Double(s.imageQuality) / 100
        let imageLabelFontAlpha = Double(s.imageLabelFontOpacity) / 100
        let imageLabels = OrderedSet(s.imageLabels).map { $0 }
        let imageFormatEXT = s.imageFormat.rawValue.uppercased()
        
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
        
        let outputPath = try makeOutputPath(for: projectName)
        
        let videoPath = try findMedia(name: projectName, paths: s.mediaSearchPaths)
        
        logger.info("Using \(s.exportFormat.name) export profile.")
        
        logger.info("Found project media file \(videoPath.path.quoted).")
        logger.info("Generating metadata file(s) with \(imageFormatEXT) images into \(outputPath.path.quoted).")
        
        let labelProperties = MarkerLabelProperties(
            fontName: s.imageLabelFont,
            fontMaxSize: s.imageLabelFontMaxSize,
            fontColor: NSColor(hexString: s.imageLabelFontColor, alpha: imageLabelFontAlpha),
            fontStrokeColor: NSColor(
                hexString: s.imageLabelFontStrokeColor,
                alpha: imageLabelFontAlpha
            ),
            fontStrokeWidth: s.imageLabelFontStrokeWidth,
            alignHorizontal: s.imageLabelAlignHorizontal,
            alignVertical: s.imageLabelAlignVertical
        )
        
        do {
            switch s.exportFormat {
            case .airtable:
                try AirtableExportProfile.export(
                    markers: markers,
                    idMode: s.idNamingMode,
                    videoPath: videoPath,
                    outputPath: outputPath,
                    payload: .init(projectName: projectName, outputPath: outputPath),
                    imageSettings: .init(
                        gifFPS: s.gifFPS,
                        gifSpan: s.gifSpan,
                        format: s.imageFormat,
                        quality: imageQuality,
                        dimensions: calcVideoDimensions(for: videoPath),
                        labelFields: imageLabels,
                        labelCopyright: s.imageLabelCopyright,
                        labelProperties: labelProperties,
                        imageLabelHideNames: s.imageLabelHideNames
                    ),
                    createDoneFile: s.createDoneFile,
                    doneFilename: s.doneFilename
                )
            case .notion:
                try NotionExportProfile.export(
                    markers: markers,
                    idMode: s.idNamingMode,
                    videoPath: videoPath,
                    outputPath: outputPath,
                    payload: .init(projectName: projectName, outputPath: outputPath),
                    imageSettings: .init(
                        gifFPS: s.gifFPS,
                        gifSpan: s.gifSpan,
                        format: s.imageFormat,
                        quality: imageQuality,
                        dimensions: calcVideoDimensions(for: videoPath),
                        labelFields: imageLabels,
                        labelCopyright: s.imageLabelCopyright,
                        labelProperties: labelProperties,
                        imageLabelHideNames: s.imageLabelHideNames
                    ),
                    createDoneFile: s.createDoneFile,
                    doneFilename: s.doneFilename
                )
            }
        } catch {
            throw MarkersExtractorError.runtimeError(
                "Failed to export: \(error.localizedDescription)"
            )
        }
        
        logger.info("Done!")
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
            markers = try FCPXMLMarkerExtractor.extractMarkers(
                from: s.fcpxml,
                idNamingMode: s.idNamingMode,
                includeOutsideClipBoundaries: s.includeOutsideClipBoundaries,
                enableSubframes: s.enableSubframes
            )
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
        let outputPath = s.outputDir.appendingPathComponent(
            "\(projectName) \(nowTimestamp())"
        )
        
        do {
            try FileManager.default.mkdirWithParent(outputPath.path, reuseExisting: false)
        } catch {
            throw MarkersExtractorError.runtimeError(
                "Failed to create output dir \(outputPath.path.quoted): \(error.localizedDescription)"
            )
        }
        
        return outputPath
    }
    
    private func nowTimestamp() -> String {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh-mm-ss"
        return formatter.string(from: now)
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
