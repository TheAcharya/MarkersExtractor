//
//  MarkersExtractor Media.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import Foundation
import AppKit
import AVFoundation
import OrderedCollections

extension MarkersExtractor {
    /// - Throws: ``MarkersExtractorError``
    func formExportMedia(
        projectName: String
    ) throws -> ExportMedia {
        let videoPath = try findMedia(name: projectName, paths: s.mediaSearchPaths)
        
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
                "Found more than one media candidate for \(name.quoted). Using first match: \(selection.path.quoted)"
            )
        }
        
        return selection
    }
    
    /// - Throws: ``MarkersExtractorError``
    private func matchFiles(at path: URL, name: String, exts: [String]) throws -> [URL] {
        do {
            return try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
                .filter {
                    $0.lastPathComponent.starts(with: name)
                    && exts.contains($0.fileExtension)
                }
        } catch {
            throw MarkersExtractorError.extraction(
                .filePermission(error.localizedDescription)
            )
        }
    }
}
