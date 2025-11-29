//
//  MarkersExtractor Utilities.swift
//  MarkersExtractor • https://github.com/TheAcharya/MarkersExtractor
//  Licensed under MIT License
//

import AVFoundation
import Foundation
import SwiftExtensions

// MARK: - Output Path

extension MarkersExtractor {
    func makeOutputPath(forTimelineName timelineName: String) throws -> URL {
        let folderName = settings.exportFolderFormat.folderName(
            timelineName: timelineName,
            profile: settings.exportFormat
        )
        let proposedOutputURL = settings.outputDir.appendingPathComponent(folderName)
        let outputURL = FileManager.default.uniqueFileURL(proposedPath: proposedOutputURL)
        try FileManager.default.mkdirWithParent(outputURL.path, reuseExisting: false)
        
        return outputURL
    }
}

// MARK: - Helpers

extension MarkersExtractor {
    func calcVideoDimensions(for videoPath: URL) -> CGSize? {
        if settings.imageWidth != nil || settings.imageHeight != nil {
            return CGSize(width: settings.imageWidth ?? 0, height: settings.imageHeight ?? 0)
        } else if let imageSizePercent = settings.imageSizePercent {
            return calcVideosSizePercent(at: videoPath, for: imageSizePercent)
        }
        
        return nil
    }
    
    func calcVideosSizePercent(at path: URL, for percent: Int) -> CGSize? {
        let asset = AVAsset(url: path)
        let ratio = Double(percent) / 100
        
        guard let origDimensions = asset.firstVideoTrack?.dimensions else {
            return nil
        }
        
        return origDimensions * ratio
    }
}
