//
//  MarkersExtractor Media.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AppKit
import AVFoundation
import Foundation
import OrderedCollections

extension MarkersExtractor {
    /// - Throws: ``MarkersExtractorError``
    func formExportMedia(
        timelineName: String
    ) throws -> ExportMedia {
        let videoPath = try findMedia(name: timelineName, paths: settings.mediaSearchPaths)
        let imageLabels = OrderedSet(settings.imageLabels).map { $0 }
        let labelProperties = MarkerLabelProperties(using: settings)
        
        let imageSettings = ExportImageSettings(
            gifFPS: settings.gifFPS,
            gifSpan: settings.gifSpan,
            format: settings.imageFormat,
            quality: settings.imageQualityDouble,
            dimensions: calcVideoDimensions(for: videoPath),
            labelFields: imageLabels,
            labelCopyright: settings.imageLabelCopyright,
            labelProperties: labelProperties,
            imageLabelHideNames: settings.imageLabelHideNames
        )
        
        return ExportMedia(videoURL: videoPath, imageSettings: imageSettings)
    }
}

// MARK: - Helpers

extension MarkersExtractor {
    /// - Throws: ``MarkersExtractorError``
    private func findMedia(name: String, paths: [URL]) throws -> URL {
        let mediaFormats = ["mov", "mp4", "m4v", "mxf", "avi", "mts", "m2ts", "3gp"]
        
        let files: [URL] = try paths.reduce(into: []) { base, path in
            let matches = try matchFiles(at: path, name: name, exts: mediaFormats)
            base.append(contentsOf: matches)
        }
        
        if files.isEmpty {
            throw MarkersExtractorError.extraction(
                .noMediaFound("No media found for \(name.quoted).")
            )
        }
        
        let selection = files[0]
        
        if files.count > 1 {
            logger.info(
                "Found more than one media candidate for \(name.quoted). Using first match: \(selection.path.quoted)."
            )
        }
        
        return selection
    }
    
    /// - Throws: ``MarkersExtractorError``
    private func matchFiles(at path: URL, name: String, exts: [String]) throws -> [URL] {
        do {
            return try FileManager.default
                .contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
                .filter {
                    $0.lastPathComponent.starts(with: name)
                        && exts.contains($0.fileExtension ?? "")
                }
        } catch {
            throw MarkersExtractorError.extraction(
                .filePermission(error.localizedDescription)
            )
        }
    }
}
